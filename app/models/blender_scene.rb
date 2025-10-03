class BlenderScene < ApplicationRecord
  STORE_ACCESSORS = {
    frame_range: [ :type, :start, :end, :step, :single ],
    resolution: [ :x, :y, :percentage ],
    sampling: [ :use_adaptive, :noise_threshold, :min_samples, :max_samples ],
    file_output: [ :file_format, :color_mode, :color_depth, :ffmpeg_format,
      :ffmpeg_codec, :film_transparent ],
    camera: [ :name, :name_options ],
    post_processing: [ :use_compositing, :use_sequencer, :use_stamp ],
  }

  belongs_to :project

  before_update :sanitize_settings

  STORE_ACCESSORS.each do |store, attributes|
    store_accessor store, *attributes, prefix: true
  end

  def self.permitted_params
    STORE_ACCESSORS.flat_map do |store, attributes|
      attributes.map { |attr| "#{store}_#{attr}".to_sym }
    end
  end

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

  def frames
    @frames ||= if frame_range_type.to_sym == :animation
      (frame_range_start..frame_range_end).step(frame_range_step).to_a
    elsif project.frame_range_type.to_sym == :image
      [ project.frame_range_single ]
    else
      raise "Unknown frame range type: #{project.frame_range_type}"
    end
  end

  private
    def sanitize_settings
    end
end
