class QuotesController < ApplicationController
  allow_unauthenticated_access

  def create
    @quote = Quote.new(quote_params)

    if @quote.save
      redirect_back fallback_location: projects_path
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def quote_params
      params.expect(quote: [ project_uuids: [] ])
    end
end
