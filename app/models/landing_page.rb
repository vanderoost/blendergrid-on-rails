class LandingPage < ApplicationRecord
  has_many :page_variants
  has_one :affiliate

  def to_param
    slug
  end

  def sections
    variant.sections
  end

  private
    def variant
      @variant ||= choose_variant
    end

    def choose_variant
      # TODO: Merge multiple page variants into one to enable A/B testing
      @variant = page_variants.last
      Current.track_event(@variant, action: :showed)
      @variant
    end
end
