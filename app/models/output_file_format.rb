class OutputFileFormat
  FORMATS = [
    { id: :bmp, name: "BMP", color_modes: [ :bw, :rgb, :rgba ] },
    { id: :iris, name: "Iris", color_modes: [ :bw, :rgb, :rgba ] },
    { id: :png, name: "PNG", color_modes: [ :bw, :rgb, :rgba ],
      color_depths: [ 8, 16 ] },
    { id: :jpeg, name: "JPEG", color_modes: [ :bw, :rgb ] },
    { id: :jpeg2000, name: "JPEG 2000", color_modes: [ :bw, :rgb, :rgba ],
      color_depths: [ 8, 12, 16 ] },
    { id: :targa, name: "Targa", color_modes: [ :bw, :rgb, :rgba ] },
    { id: :targa_raw, name: "Targa Raw", color_modes: [ :bw, :rgb, :rgba ] },
    { id: :cineon, name: "Cineon", color_modes: [ :bw, :rgb ] },
    { id: :dpx, name: "DPX", color_modes: [ :bw, :rgb, :rgba ],
      color_depths: [ 8, 10, 12, 16 ] },
    { id: :open_exr_multilayer, name: "OpenEXR MultiLayer",
      color_depths: [ 16, 32 ] },
    { id: :open_exr, name: "OpenEXR", color_modes: [ :bw, :rgb, :rgba ],
      color_depths: [ 16, 32 ] },
    { id: :hdr, name: "Radiance HDR", color_modes: [ :bw, :rgb ] },
    { id: :tiff, name: "TIFF", color_modes: [ :bw, :rgb, :rgba ],
      color_depths: [ 8, 16 ] },
    { id: :webp, name: "WebP", color_modes: [ :bw, :rgb, :rgba ] },
    { id: :ffmpeg, name: "FFmpeg Video", color_modes: [ :bw, :rgb ], video: true },
  ]

  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :id, :string
  attribute :name, :string
  attribute :color_modes, default: []
  attribute :color_depths, default: []
  attribute :video, :boolean, default: false

  def self.all
    self::FORMATS.map do |attrs|
      attrs[:id] = attrs[:id].upcase
      new(attrs)
    end
  end

  def self.find(id)
    new(self::FORMATS.find { |f| f[:id].to_s.upcase == id.to_s.upcase })
  end
end

class FfmpegFormat
  FORMATS = [
    { id: :mpeg4, name: "MPEG-4", codecs: true },
    { id: :mkv, name: "Matroska", codecs: true },
    { id: :webm, name: "WebM", codecs: true },
    { id: :avi, name: "AVI", codecs: true },
    { id: :dv, name: "DV" },
    { id: :flash, name: "Flash" },
    { id: :mpeg1, name: "MPEG-1" },
    { id: :mpeg2, name: "MPEG-2" },
    { id: :ogg, name: "Ogg", codecs: true },
    { id: :quicktime, name: "QuickTime", codecs: true },
  ]

  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :id, :string
  attribute :name, :string
  attribute :codecs, :boolean, default: false

  def self.all
    self::FORMATS.map do |attrs|
      attrs[:id] = attrs[:id].to_s.upcase
      new(attrs)
    end
  end

  def self.find(id)
    new(self::FORMATS.find { |f| f[:id].to_s.upcase == id.to_s.upcase })
  end
end

class FfmpegCodec
  CODECS = [
    { id: :av1, name: "AV1", color_depths: [ 8, 10, 12 ] },
    { id: :h264, name: "H.264", color_depths: [ 8, 10 ] },
    { id: :h265, name: "H.265 / HEVC", color_depths: [ 8, 10, 12 ] },
    { id: :webm, name: "WebM / VP9" },
    { id: :dnxhd, name: "DNxHD" },
    { id: :ffv1, name: "FFmpeg video codec #1", color_depths: [ 8, 10, 12, 16 ] },
    { id: :flash, name: "Flash Video" },
    { id: :huffyuv, name: "HuffYUV" },
    { id: :mpeg1, name: "MPEG-1" },
    { id: :mpeg2, name: "MPEG-2" },
    { id: :mpeg4, name: "MPEG-4 (divx)" },
    { id: :png, name: "PNG" },
    { id: :prores, name: "ProRes", color_depths: [ 8, 10 ] },
    { id: :qtrle, name: "QuickTime Animation" },
    { id: :theora, name: "Theora" },
  ]

  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :id, :string
  attribute :name, :string
  attribute :color_depths, default: []

  def self.all
    self::CODECS.map do |attrs|
      attrs[:id] = attrs[:id].to_s.upcase
      new(attrs)
    end
  end

  def self.find(id)
    new(self::CODECS.find { |f| f[:id].to_s.upcase == id.to_s.upcase })
  end
end
