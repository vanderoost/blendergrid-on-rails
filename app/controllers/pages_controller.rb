class PagesController < ApplicationController
  allow_unauthenticated_access

  def pricing
  end

  def policies
    slug = params[:slug]

    return unless slug

    # TODO: Move this into a model or something
    md_path = Rails.root / "app" / "views" / "pages" / "policies" / "#{slug}.md"

    raise ActionController::RoutingError.new("Not Found") unless File.exist?(md_path)

    markdown_content = File.read(md_path)
    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML,
      autolink: true,
      tables: true,
      fenced_code_blocks: true
    )
    @content_html = markdown.render(markdown_content)
  end
end
