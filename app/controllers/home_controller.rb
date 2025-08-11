class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @upload = Upload.new
  end
end
