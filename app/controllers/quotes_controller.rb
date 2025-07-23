class QuotesController < ApplicationController
  include ProjectScoped

  allow_unauthenticated_access only: %i[ create ]

  def create
    @quote = @project.build_quote
    if @quote.save
      redirect_to @project
    else
      render :new, status: :unprocessable_entity
    end
  end
end
