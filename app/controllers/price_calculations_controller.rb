class PriceCalculationsController < ApplicationController
  allow_unauthenticated_access

  def create
    for project in Project.where(uuid: params[:project_uuids])
      project.calculate_price
    end
  end
end
