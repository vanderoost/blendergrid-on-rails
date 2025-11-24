class AuthorsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_articles, only: %i[ show ]

  def show
  end

  private
    def set_articles
      user = User.find_by!(name: params.expect(:slug).titleize)
      @articles = user.articles
    end
end
