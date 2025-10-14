class PagesController < ApplicationController
  allow_unauthenticated_access

  def pricing
  end

  def legal
    @page_slug = params[:page]
    markdown_path = Rails.root.join(
      "app",
      "views",
      "pages",
      "legal",
      "#{@page_slug}.md"
    )

    unless File.exist?(markdown_path)
      raise ActionController::RoutingError.new("Not Found")
    end

    markdown_content = File.read(markdown_path)
    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML,
      autolink: true,
      tables: true,
      fenced_code_blocks: true
    )
    @content_html = markdown.render(markdown_content)
  end
end
