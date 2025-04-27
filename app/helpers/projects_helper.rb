module ProjectsHelper
  STATUS_UI = {
    uploaded:           { color: "slate",   icon: "arrow-up-tray"      },
    checking_integrity: { color: "amber",   icon: "arrow-path", class: "animate-spin" },
    integrity_checked:  { color: "emerald", icon: "check-badge"        },
    calculating_price:  { color: "indigo",  icon: "calculator"         },
    price_calculated:   { color: "sky",     icon: "currency-dollar"    },
    rendering:          { color: "blue",    icon: "cpu-chip"           },
    finished:           { color: "green",   icon: "check-circle"       },
    cancelled:          { color: "gray",    icon: "x-circle"           },
    failed:             { color: "rose",    icon: "exclamation-circle" },
    deleted:            { color: "zinc",    icon: "trash"              }
  }.freeze

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

  def status_icon(project, **options)
    spec   = STATUS_UI.fetch(project.status.to_sym)
    classes = options[:class].to_s.split
    classes << spec[:class] if spec[:class]

    icon spec[:icon], class: classes.join(" ")
  end
end
