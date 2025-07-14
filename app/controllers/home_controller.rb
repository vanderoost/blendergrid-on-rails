class HomeController < ApplicationController
  def index
    @upload = Upload.new
  end
end
