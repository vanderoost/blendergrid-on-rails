class FaqsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_faq, only: %i[ update ]

  def index
    @faqs = Faq.all
  end

  def update
    @faq.increment!(:clicks)
  end

  private
    def set_faq
      @faq = Faq.find(params[:id])
    end
end
