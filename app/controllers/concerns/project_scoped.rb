module ProjectScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_project
  end

  private
    def set_project
      @project = Project.find_by(uuid: params[:project_uuid])
    end
end
