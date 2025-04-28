class PriceCalculationsController < ApplicationController
  allow_unauthenticated_access

  def create
    Rails.logger.info "CREATE WORKFLOW - Params: #{params.inspect}"

    project_uuids = params[:project_uuids] || {}

    # Then, select only the ones that are "1"
    enabled_uuids = project_uuids.select { |uuid, value| value == "1" }.keys

    # Finally, query your Project model
    projects = Project.where(uuid: enabled_uuids)

    for project in projects
      project.state.calculate_price
    end
  end
end
