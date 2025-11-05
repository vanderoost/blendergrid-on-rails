class OutputFileFormat
  FORMATS = [
    { id: :bmp, name: "BMP", color_modes: [ :BW, :RGB, :RGBA ] },
    { id: :iris, name: "Iris", color_modes: [ :BW, :RGB, :RGBA ] },
    { id: :png, name: "PNG", color_modes: [ :BW, :RGB, :RGBA ],
      color_depths: [ 8, 16 ] },
    { id: :jpeg, name: "JPEG", color_modes: [ :BW, :RGB ] },
    { id: :jpeg2000, name: "JPEG 2000", color_modes: [ :BW, :RGB, :RGBA ],
      color_depths: [ 8, 12, 16 ] },
    { id: :targa, name: "Targa", color_modes: [ :BW, :RGB, :RGBA ] },
    { id: :targa_raw, name: "Targa Raw", color_modes: [ :BW, :RGB, :RGBA ] },
    { id: :cineon, name: "Cineon", color_modes: [ :BW, :RGB ] },
    { id: :dpx, name: "DPX", color_modes: [ :BW, :RGB, :RGBA ],
      color_depths: [ 8, 10, 12, 16 ] },
    { id: :open_exr_multilayer, name: "OpenEXR MultiLayer",
      color_depths: [ 16, 32 ] },
    { id: :open_exr, name: "OpenEXR", color_modes: [ :BW, :RGB, :RGBA ],
      color_depths: [ 16, 32 ] },
    { id: :hdr, name: "Radiance HDR", color_modes: [ :BW, :RGB ] },
    { id: :tiff, name: "TIFF", color_modes: [ :BW, :RGB, :RGBA ],
      color_depths: [ 8, 16 ] },
    { id: :webp, name: "WebP", color_modes: [ :BW, :RGB, :RGBA ] },
    { id: :ffmpeg, name: "FFmpeg Video", color_modes: [ :BW, :RGB ],
      video: true },
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
    { id: :MPEG4, name: "MPEG-4", extension: ".mp4", codecs: true },
    { id: :MKV, name: "Matroska", extension: ".mkv", codecs: true },
    { id: :WEBM, name: "WebM", extension: ".webm", codecs: true },
    { id: :AVI, name: "AVI", extension: ".avi", codecs: true },
    { id: :DV, extension: ".dv", name: "DV" },
    { id: :FLASH, extension: ".swf", name: "Flash" },
    { id: :MPEG1, extension: ".mpg", name: "MPEG-1" },
    { id: :MPEG2, extension: ".mpg", name: "MPEG-2" },
    { id: :OGG, name: "Ogg", extension: ".ogg", codecs: true },
    { id: :QUICKTIME, name: "QuickTime", extension: ".mov", codecs: true },
  ]

  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :id, :string
  attribute :name, :string
  attribute :extension, :string
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
    { id: :AV1, name: "AV1", color_depths: [ 8, 10, 12 ] },
    { id: :H264, name: "H.264", color_depths: [ 8, 10 ] },
    { id: :H265, name: "H.265 / HEVC", color_depths: [ 8, 10, 12 ] },
    { id: :WEBM, name: "WebM / VP9" },
    { id: :DNXHD, name: "DNxHD" },
    { id: :FFV1, name: "FFmpeg video codec #1", color_depths: [ 8, 10, 12, 16 ] },
    { id: :FLASH, name: "Flash Video" },
    { id: :HUFFYUV, name: "HuffYUV" },
    { id: :MPEG1, name: "MPEG-1" },
    { id: :MPEG2, name: "MPEG-2" },
    { id: :MPEG4, name: "MPEG-4 (divx)" },
    { id: :PNG, name: "PNG" },
    { id: :PRORES, name: "ProRes", color_depths: [ 8, 10 ] },
    { id: :QTRLE, name: "QuickTime Animation" },
    { id: :THEORA, name: "Theora" },
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
