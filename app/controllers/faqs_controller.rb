class FaqsController < ApplicationController
  allow_unauthenticated_access

  def index
    @faqs = Faq.all
  end
end
