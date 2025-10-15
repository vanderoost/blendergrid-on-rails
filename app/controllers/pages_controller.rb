class PagesController < ApplicationController
  allow_unauthenticated_access

  # Define allowed policy pages to prevent path traversal
  ALLOWED_POLICIES = %w[terms privacy refund].freeze

  def pricing
  end

  def policies
    slug = params[:slug]

    return unless slug

    # TODO: Move this into a model or something
    unless ALLOWED_POLICIES.include?(slug)
      raise ActionController::RoutingError.new("Not Found")
    end

    md_path = Rails.root / "app" / "views" / "pages" / "policies" / "#{slug}.md"

    raise ActionController::RoutingError.new("Not Found") unless File.exist?(md_path)

    markdown_content = File.read(md_path)
    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(safe_links_only: true),
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      no_intra_emphasis: true
    )
    @content_html = markdown.render(markdown_content)
  end
end
