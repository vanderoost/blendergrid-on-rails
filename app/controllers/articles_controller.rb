class ArticlesController < ApplicationController
  allow_unauthenticated_access
  before_action :set_article, only: %i[ show ]

  def index
    @articles = Article.all
  end

  def show
  end

  private
    def set_article
      @article = Article.find_by!(slug: params.expect(:slug))
    end
end
