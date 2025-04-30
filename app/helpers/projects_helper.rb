module ProjectsHelper
  STATUS_UI = {
    uploaded:           { color: "slate",   icon: "arrow-up-tray"      },
    checking_integrity: { color: "amber",   icon: "arrow-path", class: "animate-spin" },
    checked:  { color: "emerald", icon: "check-badge"        },
    calculating_price:  { color: "indigo",  icon: "calculator"         },
    waiting:   { color: "sky",     icon: "currency-dollar"    },
    rendering:          { color: "blue",    icon: "cpu-chip"           },
    finished:           { color: "green",   icon: "check-circle"       },
    cancelled:          { color: "gray",    icon: "x-circle"           },
    failed:             { color: "rose",    icon: "exclamation-circle" },
    deleted:            { color: "zinc",    icon: "trash"              }
  }.freeze

  # TODO: Deprecate this, turn into a partial
  def status_badge(project, **options)
    spec   = STATUS_UI.fetch(project.status.to_sym)
    text   = Project.human_attribute_name("status.#{project.status}")
    color = spec[:color]

    classes = options[:class].to_s.split
    classes << "rounded-md bg-#{color}-50 px-2 py-1 text-xs font-medium text-#{color}-700 ring-1 ring-#{color}-600/20 ring-inset"

    content_tag :span, class: classes.join(" "), id: dom_id(project, :status) do
        text
    end
  end

  def status_text(project)
    Project.human_attribute_name("status.#{project.status}")
  end

  def status_color(project)
    STATUS_UI.fetch(project.status.to_sym)[:color]
  end

  def status_icon(project, **options)
    spec   = STATUS_UI.fetch(project.status.to_sym)
    classes = options[:class].to_s.split
    classes << spec[:class] if spec[:class]

    icon spec[:icon], class: classes.join(" ")
  end

  def short_frame_summary(project)
    frame_range = project.settings.dig("output", "frame_range")
    return unless frame_range

    start_frame = frame_range["start"]
    end_frame = frame_range["end"]

    if start_frame == end_frame
      "Single Frame"
    else
      "#{end_frame - start_frame + 1} Frame Animation"
    end
  end

  def frame_range_details(project)
    frame_range = project.settings.dig("output", "frame_range")
    return unless frame_range

    start_frame = frame_range["start"]
    end_frame = frame_range["end"]

    if start_frame == end_frame
      "Frame #{start_frame}"
    else
      "Frame #{start_frame} - #{end_frame}"
    end
  end

  def resolution_details(project)
    format = project.settings.dig("output", "format")
    return unless format

    res_percent = format["resolution_percentage"]
    res_x = (format["resolution_x"] * res_percent / 100).floor
    res_y = (format["resolution_y"] * res_percent / 100).floor

    "#{res_x} x #{res_y} px"
  end
end
