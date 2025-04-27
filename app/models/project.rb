class Project < ApplicationRecord
  belongs_to :project_source
  has_many :workflows

  enum :status, [
      :uploaded,
      :checking_integrity,
      :integrity_checked,
      :calculating_price,
      :price_calculated,
      :rendering,
      :finished,
      :cancelled,
      :failed,
      :deleted
    ], default: :uploaded

  attribute :settings, :json, default: {}
  attribute :stats, :json,  default: {}

  def state
    "ProjectStates::#{self.status.classify}".constantize.new(self)
  end

  # TODO: "Rubyfy" this and make it look clean, put it in helpser
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
    if self.settings
      samples = self.settings.dig("render", "sampling", "max_samples")
      if samples
        "Samples: #{samples}"
      else
        ""
      end
    else
      ""
    end
  end

  def frame_range_type
    if self.settings
      start_frame = self.settings.dig("output", "frame_range", "start")
      end_frame = self.settings.dig("output", "frame_range", "end")
      if start_frame && end_frame
        if start_frame == end_frame
          "Single Frame"
        else
          "Animation"
        end
      end
    else
      ""
    end
  end

  def frame_range_str
    if self.settings
      start_frame = self.settings.dig("output", "frame_range", "start")
      end_frame = self.settings.dig("output", "frame_range", "end")
      if start_frame && end_frame
        if start_frame == end_frame
          "Frame #{start_frame}"
        else
          "Frames #{start_frame} - #{end_frame}"
        end
      end
    else
      ""
    end
  end

  broadcasts_to ->(p) { [ p.project_source, :projects ] },
    partial: "projects/project",
    inserts_by: :prepend
end
