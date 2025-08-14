class LandingPage < ApplicationRecord
  has_many :page_variants

  def sections
    # TODO: Merge multiple page variants into one to enable A/B testing
    page_variants.last&.sections
  end
end
