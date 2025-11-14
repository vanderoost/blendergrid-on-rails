class ArticlesController < ApplicationController
  allow_unauthenticated_access
  before_action :set_article, only: %i[ show ]

  def index
    @articles = Article.where(published_at: ..Time.current).order(published_at: :desc)
  end

  def show
  end

  private
    def set_article
      @article = Article.find_by!(slug: params.expect(:slug))
      Current.track_event(@article, action: :showed)
    end
end
