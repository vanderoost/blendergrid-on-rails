class BlenderScene < ApplicationRecord
  belongs_to :project

  store_accessor :frame_range, :type, :start, :end, :step, :single, prefix: true
  store_accessor :resolution, :x, :y, :percentage, prefix: true
  store_accessor :sampling, :use_adaptive, :noise_threshold, :min_samples,
    :max_samples, prefix: true
  store_accessor :file_output, :file_format, :color_mode, :color_depth, :ffmpeg_format,
    :ffmpeg_codec, prefix: true

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
end
