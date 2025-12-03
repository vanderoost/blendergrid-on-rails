class AttributePageVariantJob < ApplicationJob
  queue_as :default

  def perform(user)
    return if user.page_variant_id.present?

    page_variant = find_signup_page_variant(user)
    user.update_column(:page_variant_id, page_variant.id) if page_variant
  end

  private
    def find_signup_page_variant(user)
      creation_event = user.resource_events.find_by(action: :created)
      return nil unless creation_event

      signup_request = creation_event.request
      return nil unless signup_request

      # Find first PageVariant shown to this visitor
      # in 24h before signup
      Event.joins(:request)
        .where(
          resource_type: "PageVariant",
          action: :showed,
          requests: {
            visitor_id: signup_request.visitor_id,
            created_at: (user.created_at - 24.hours)..user.created_at,
          }
        )
        .order("requests.created_at ASC")
        .first&.resource
    end
end
