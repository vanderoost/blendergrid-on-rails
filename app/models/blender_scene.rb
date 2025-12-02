class BlenderScene < ApplicationRecord
  STORE_ACCESSORS = {
    frame_range: {
      type: :string,
      start: :integer,
      end: :integer,
      step: :integer,
      single: :integer,
    },
    resolution: {
      x: :integer,
      y: :integer,
      percentage: :integer,
      use_border: :boolean,
    },
    sampling: {
      use_adaptive: :boolean,
      noise_threshold: :float,
      min_samples: :integer,
      max_samples: :integer,
    },
    file_output: {
      file_format: :string,
      color_mode: :string,
      color_depth: :string,
      ffmpeg_format: :string,
      ffmpeg_codec: :string,
      film_transparent: :boolean,
      fps: :float,
    },
    camera: {
      name: :string,
      name_options: :array,
    },
    post_processing: {
      use_compositing: :boolean,
      use_sequencer: :boolean,
      use_stamp: :boolean,
    },
  }

  include JsonAccessible

  belongs_to :project

  def file_output_color_mode
    color_mode = self.file_output["color_mode"]
    return color_mode if output_file_format.color_modes.map(&:to_s).include?(color_mode)
    output_file_format.color_modes.last.to_s
  end

  def file_output_color_depth
    color_depth = self.file_output["color_depth"]
    if file_output_color_depth_options.map(&:to_s).include?(color_depth)
      color_depth
    elsif output_file_format.video
      file_output_color_depth_options.first.to_s
    else
      output_file_format.color_depths.last.to_s
    end
  end

  def file_output_color_depth_options
    if output_file_format.video
      output_ffmpeg_codec.color_depths
    else
      output_file_format.color_depths
    end
  end

  def output_ffmpeg_codec
    return nil unless output_ffmpeg_format.present?
    @output_ffmpeg_codec ||= FfmpegCodec.find(file_output_ffmpeg_codec)
  end

  def output_ffmpeg_format
    return nil unless output_file_format.video
    @output_ffmpeg_format ||= FfmpegFormat.find(file_output_ffmpeg_format)
  end

  def output_file_format
    @output_file_format ||= OutputFileFormat.find(file_output_file_format)
  end

  def scaled_resolution_x(percentage = nil)
    (resolution_x * (percentage || resolution_percentage).fdiv(100)).to_i
  end

  def scaled_resolution_y(percentage = nil)
    (resolution_y * (percentage || resolution_percentage).fdiv(100)).to_i
  end

  def frames
    @frames ||= if frame_range_type.to_sym == :animation
      (frame_range_start..frame_range_end).step(frame_range_step).to_a
    elsif project.frame_range_type.to_sym == :image
      [ project.frame_range_single ]
    else
      raise "Unknown frame range type: #{project.frame_range_type}"
    end
  end

  def settings_hash
    {
      frame_range: frame_range,
      resolution: resolution,
      sampling: sampling,
      file_output: file_output,
      camera: camera,
      post_processing: post_processing,
    }
  end
end
