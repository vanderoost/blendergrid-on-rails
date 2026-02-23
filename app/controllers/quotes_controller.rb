class QuotesController < ApplicationController
  allow_unauthenticated_access

  def create
    @quote = Quote.new(quote_params)

    if @quote.save
      if return_path_param
        redirect_to return_path_param
      else
        redirect_back fallback_location: projects_path
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def quote_params
      params.expect(quote: [ project_uuids: [] ])
    end

    def return_path_param
      path = params[:return_path]
      path if path&.start_with?("/")
    end
end
