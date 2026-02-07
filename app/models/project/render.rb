require "aws-sdk-s3"

class Project::Render < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include Workflowable

  belongs_to :project

  before_destroy :cancel_project

  def self.aggregates
    scope = where.not(total_samples: nil)
    row = scope.pick(
      Arel.sql("COUNT(*)"),
      Arel.sql("AVG(frame_count)"),
      Arel.sql("AVG(pixel_count)"),
      Arel.sql("AVG(max_samples)"),
      Arel.sql("AVG(total_samples)"),
      Arel.sql("AVG(price_cents)"),
      Arel.sql(
        "AVG(price_cents * 1.0 "\
        "/ NULLIF(frame_count, 0))"
      ),
      Arel.sql("AVG(cents_per_gigasample)"),
      *stddev_expressions
    )

    {
      count: row[0],
      frame_count: {
        mean: row[1]&.to_f, stddev: row[8]&.to_f,
      },
      pixel_count: {
        mean: row[2]&.to_f, stddev: row[9]&.to_f,
      },
      max_samples: {
        mean: row[3]&.to_f, stddev: row[10]&.to_f,
      },
      total_samples: {
        mean: row[4]&.to_f, stddev: row[11]&.to_f,
      },
      price_cents: {
        mean: row[5]&.to_f, stddev: row[12]&.to_f,
      },
      price_per_frame: {
        mean: row[6]&.to_f, stddev: row[13]&.to_f,
      },
      cents_per_gigasample: {
        mean: row[7]&.to_f, stddev: row[14]&.to_f,
      },
    }
  end

  def self.estimate(
    frame_count: nil,
    resolution_x: nil,
    resolution_y: nil,
    max_samples: nil
  )
    agg = aggregates
    return nil if agg[:count].zero?

    fc = frame_count || agg[:frame_count][:mean]
    rx = resolution_x
    ry = resolution_y
    px = if rx && ry
      rx * ry
    else
      agg[:pixel_count][:mean]
    end
    ms = max_samples || agg[:max_samples][:mean]

    ts = fc * px * ms
    cpgs_mean = agg[:cents_per_gigasample][:mean]
    cpgs_sd =
      agg[:cents_per_gigasample][:stddev] || 0

    price =
      (cpgs_mean * ts / 1_000_000_000.0).round
    low = (
      (cpgs_mean - cpgs_sd) * ts /
      1_000_000_000.0
    ).round
    high = (
      (cpgs_mean + cpgs_sd) * ts /
      1_000_000_000.0
    ).round

    {
      price_cents: price,
      confidence_low: [ low, 0 ].max,
      confidence_high: high,
      total_samples: ts.round,
      inputs: {
        frame_count: fc,
        pixel_count: px,
        max_samples: ms,
      },
    }
  end

  private_class_method \
    def self.stddev_expressions
      if connection.adapter_name == "PostgreSQL"
        stddev_columns.map do |col|
          Arel.sql("STDDEV(#{col})")
        end
      else
        stddev_columns.map do |col|
          Arel.sql(
            "SQRT(AVG("\
            "(#{col} - (SELECT AVG(#{col}) "\
            "FROM project_renders "\
            "WHERE total_samples IS NOT NULL)) "\
            "* (#{col} - (SELECT AVG(#{col}) "\
            "FROM project_renders "\
            "WHERE total_samples IS NOT NULL))"\
            "))"
          )
        end
      end
    end

  private_class_method \
    def self.stddev_columns
      %w[
        frame_count pixel_count max_samples
        total_samples price_cents
        price_cents*1.0/NULLIF(frame_count,0)
        cents_per_gigasample
      ]
    end

  def owner = project

  def make_start_message
    swarm_engine_env =
      Rails.configuration.swarm_engine[:env]

    bucket.object(
      "projects/#{project.uuid}/jsons/settings.json"
    ).put(
      body: project.settings_hash.to_json,
      content_type: "application/json"
    )

    {
      workflow_id: workflow.uuid,
      deadline: workflow.project
        .tweaks_deadline_hours.hours.from_now.to_i,
      files: {
        input: {
          scripts: "s3://blendergrid-blender-scripts"\
            "/#{swarm_engine_env}",
        },
        logs: "#{s3_project_path}/logs",
      },
      executions: executions,
      metadata: {
        type: "render",
        created_by: "blendergrid-on-rails",
        project_uuid: project.uuid,
        project_name: project.blend_filepath,
      },
    }
  end

  def handle_completion
    project.finish_rendering if workflow.finished?
    project.fail if workflow.failed?
    populate_stats! if workflow.finished?
  end

  def populate_stats!
    proj = Project.unscoped.find(project_id)
    scene = proj.current_blender_scene
    return unless scene

    tweaks = proj.tweaks || {}
    res_pct = tweaks["resolution_percentage"]
    rx = scene.scaled_resolution_x(res_pct)
    ry = scene.scaled_resolution_y(res_pct)
    samples = tweaks["sampling_max_samples"] ||
      scene.sampling_max_samples
    fc = frame_count_for(proj, scene)
    px = rx * ry
    ts = fc * px * samples
    pc = proj.price_cents

    cpgs = if ts.positive? && pc
      (pc * 1_000_000_000.0 / ts).round
    end

    update!(
      frame_count: fc,
      resolution_x: rx,
      resolution_y: ry,
      pixel_count: px,
      max_samples: samples,
      total_samples: ts,
      price_cents: pc,
      cents_per_gigasample: cpgs
    )
  end

  private
    def frame_count_for(proj, scene)
      if scene.frame_range_type.to_sym == :animation
        scene.frames.count
      else
        proj.frame_range_single ? 1 : 0
      end
    end

    def executions
      render_ex_id = SecureRandom.uuid
      result = [ render_execution(render_ex_id) ]

      if project.frames.count > 1
        result << zip_execution(render_ex_id)

        if project.file_output_file_format == "FFMPEG"
          result << video_encoding(render_ex_id)
        end
      end

      result
    end

    def render_execution(render_ex_id)
      expected_duration = project.job_time || 3.minutes
      {
        execution_id: render_ex_id,
        job_id: "frame-$frame",
        files: render_files,
        command: [
          "--enable-autoexec",
          "/tmp/project/#{project.blend_filepath}",
          "--scene",
          project.current_blender_scene.name,
          "--python",
          "/tmp/scripts/init.py",
          "-o",
          "/tmp/frames/frame-",
          "-f",
          "$frame",
          "--",
          "--settings-file",
          "/tmp/settings/settings.json",
          "--project-dir",
          "/tmp/project",
          "--cycles-samples",
          project.sampling_max_samples.to_s,
        ],
        parameters: { frame: frame_params },
        expected_duration:
          expected_duration.in_milliseconds.round,
        expected_output_files: [
          "#{s3_project_path}/frames"\
          "/frame-$frame#{project.frame_extension}",
        ],
        image:
          "blendergrid/blender:"\
          "#{project.blender_version}",
      }
    end

    def zip_execution(render_ex_id)
      {
        job_id: "compress-frames",
        files: zip_files,
        command: [
          "python3",
          "/tmp/scripts/compress-chunks.py",
          "/tmp/frames",
          "/tmp/zip/#{project.name}-frames",
        ],
        dependencies: [ render_ex_id ],
        image: "blendergrid/tools",
      }
    end

    def video_encoding(render_ex_id)
      frame_digits =
        [ 4, project.frames.last.to_s.length ].max
      {
        job_id: "encode-video",
        files: video_encoding_files,
        command: [
          "ffmpeg",
          "-framerate",
          project.file_output_fps.to_s,
          "-start_number",
          project.frames.first.to_s,
          "-i",
          "/tmp/frames/frame-"\
          "%0#{frame_digits}d.png",
          "-vf",
          "pad=ceil(iw/2)*2:ceil(ih/2)*2",
          "-pix_fmt", "yuv420p",
          "-y",
          "/tmp/ffmpeg/#{project.name}"\
          "#{project.ffmpeg_extension}",
        ],
        dependencies: [ render_ex_id ],
        image: "blendergrid/tools",
      }
    end

    def render_files
      key_prefix =
        Rails.configuration.swarm_engine[:key_prefix]
      {
        input: {
          project: "s3://#{bucket_name}"\
            "/#{key_prefix}/#{project.upload.uuid}",
          settings: "#{s3_project_path}/jsons",
        },
        output: {
          frames: "#{s3_project_path}/frames",
        },
      }
    end

    def zip_files
      {
        input: {
          frames: "#{s3_project_path}/frames",
        },
        output: {
          zip: "#{s3_project_path}/output",
        },
      }
    end

    def video_encoding_files
      {
        input: {
          frames: "#{s3_project_path}/frames",
        },
        output: {
          ffmpeg: "#{s3_project_path}/output",
        },
      }
    end

    def frame_params
      if project.frame_range_type == "animation"
        {
          start: project.frame_range_start,
          end: project.frame_range_end,
          step: project.frame_range_step,
        }
      elsif project.frame_range_type == "image"
        project.frame_range_single
      else
        raise "Unknown frame range type: "\
          "#{project.frame_range_type}"
      end
    end

    def cancel_project
      project.cancel
    end

    def s3_project_path
      "s3://#{bucket_name}/projects/#{project.uuid}"
    end

    def bucket
      @bucket ||= s3.bucket(bucket_name)
    end

    def bucket_name
      @bucket_name ||=
        Rails.configuration.swarm_engine[:bucket]
    end

    def s3
      @s3 ||= Aws::S3::Resource.new
    end
end
