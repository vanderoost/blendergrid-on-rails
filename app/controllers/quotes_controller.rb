class QuotesController < ApplicationController
  include ProjectScoped

  allow_unauthenticated_access only: %i[ create ]

  def create
    @quote = @project.quotes.new # Option to pass in any custom data from the user
    if @quote.save
      redirect_to @project
    else
      render :new, status: :unprocessable_entity
    end
  end
end
