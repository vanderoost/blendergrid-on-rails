module Project::Stages
  class Base
    include ActiveModel::Model
    attr_reader :projects

    def initialize(projects)
      @projects = projects
    end

    def to_partial_path
      "projects/stage_#{self.class.name.demodulize.underscore}"
    end

    def status
      self.class.name.demodulize.underscore.to_sym
    end

    def title
      self.class.title
    end

    def count
      projects.size
    end

    def dom_id
      "stage_#{status}"
    end

    def order
      Project::Stages::ORDER.index(self.class)
    end
  end

  class Analysis < Base
  end

  class Pricing < Base
  end

  class Rendering < Base
  end

  class Archive < Base
  end

  ORDER = [ Analysis, Pricing, Rendering, Archive ].freeze
end
