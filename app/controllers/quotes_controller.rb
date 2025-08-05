class QuotesController < ApplicationController
  include ProjectScoped

  allow_unauthenticated_access only: %i[ create ]

  def create
    @quote = @project.quotes.new(quote_params)
    if @quote.save
      redirect_back fallback_location: @project
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def quote_params
      params.expect(quote: [ :frame_range_type ])
    end
end
