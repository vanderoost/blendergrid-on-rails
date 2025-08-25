class LandingPage < ApplicationRecord
  has_many :page_variants

  def to_param
    slug
  end

  def sections
    # TODO: Merge multiple page variants into one to enable A/B testing
    variant = page_variants.last
    Current.trackable = variant
    variant.sections
  end
end
