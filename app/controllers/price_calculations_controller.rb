class PriceCalculationsController < ApplicationController
  include ProjectScoped

  allow_unauthenticated_access only: %i[ create ]

  def create
    @price_calculation = @project.build_price_calculation
    if @price_calculation.save
      redirect_to @project
    else
      render :new, status: :unprocessable_entity
    end
  end
end
