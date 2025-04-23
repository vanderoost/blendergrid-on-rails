class Project < ApplicationRecord
  belongs_to :project_source
  has_many :workflows

  enum :status,
    [ :started,  :waiting, :rendering, :finished, :failed ],
    default: :started

  attribute :settings, :json, default: {}
  attribute :stats, :json,  default: {}

  # TODO: "Rubyfy" this and make it look clean
  def resolution_str
    format = self.settings.dig("output", "format")
    if not format
      return ""
    end

    resolution_x = format.dig("resolution_x")
    resolution_y = format.dig("resolution_y")
    resolution_percentage = format.dig("resolution_percentage")
    if resolution_x && resolution_y && resolution_percentage
      resolution_x = resolution_x * resolution_percentage / 100
      resolution_y = resolution_y * resolution_percentage / 100
      "#{resolution_x}x#{resolution_y}px"
    else
      ""
    end
  end

  def samples_str
    if self.settings && self.settings["samples"]
      samples = self.settings["samples"]
      "Samples: #{samples}"
    else
      ""
    end
  end

  def frame_range_type
    if self.settings && self.settings["frame_range"]
      frame_range = self.settings["frame_range"]
      if frame_range.start == frame_range.end
        "Single Frame"
      else
        "Animation"
      end
    else
      ""
    end
  end
  def frame_range_str
    if self.settings && self.settings["frame_range"]
      frame_range = self.settings["frame_range"]
      if frame_range.start == frame_range.end
        "Frame: #{self.frame_range.start}"
      else
        "Frames: #{self.frame_range.start}-#{self.frame_range.end}"
      end
    else
      ""
    end
  end

  broadcasts_to ->(p) { [ p.project_source, :projects ] },
    partial: "projects/project",
    inserts_by: :prepend
end
