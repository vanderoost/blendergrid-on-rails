class MarkdownRenderer < Redcarpet::Render::HTML
  def preprocess(text)
    # Match tags like {% youtube dQw4w9WgXcQ %}
    text.gsub!(/{%\s*youtube\s+([\w-]+)\s*%}/) do
      %(<iframe src="https://www.youtube.com/embed/#{$1}" frameborder="0"
      allowfullscreen></iframe>)
    end

    # Match tags like {% vimeo 123456789 %}
    text.gsub!(/{%\s*vimeo\s+(\d+)\s*%}/) do
      %(<iframe src="https://player.vimeo.com/video/#{$1}" frameborder="0"
      allowfullscreen></iframe>)
    end

    text
  end
end
