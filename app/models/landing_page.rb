class LandingPage < ApplicationRecord
  has_many :page_variants

  def to_param
    slug
  end

  def sections
    variant.sections
  end

  private
    def variant
      # TODO: Merge multiple page variants into one to enable A/B testing
      return @variant if @variant
      @variant = page_variants.last
      Current.track_event(@variant, action: :showed)
      @variant
    end
end
