class MarkdownRenderer < Redcarpet::Render::HTML
  YOUTUBE_EMBED_PATTERN = %r{
    !\[([^\]]*)\]                           # Alt text
    \(
      (https?://(?:www\.)?
        (?:youtube\.com/watch\?v=|youtu\.be/)
        ([\w-]+)
        [^)]*)                               # Optional extra params (fixed)
    \)
  }x

  VIMEO_EMBED_PATTERN = %r{
    !\[([^\]]*)\]                           # Alt text
    \(
      (https?://(?:www\.)?
        vimeo\.com/
        (\d+)
        [^)]*)                               # Optional extra params (fixed)
    \)
  }x

  def preprocess(text)
    text.gsub!(YOUTUBE_EMBED_PATTERN) do
      caption = $1
      youtube_id = $3

      html = %(<figure class="video-wrapper">)
      html += %(<div class="video-container">)
      html += %(<iframe src="https://www.youtube.com/embed/#{youtube_id}"
        frameborder="0" allowfullscreen></iframe>)
      html += %(</div>)
      html += %(<figcaption>#{caption}</figcaption>) unless caption.empty?
      html += %(</figure>)
      html
    end

    text.gsub!(VIMEO_EMBED_PATTERN) do
      caption = $1
      vimeo_id = $3

      html = %(<figure class="video-wrapper">)
      html += %(<div class="video-container">)
      html += %(<iframe src="https://player.vimeo.com/video/#{vimeo_id}"
        frameborder="0" allowfullscreen></iframe>)
      html += %(</div>)
      html += %(<figcaption>#{caption}</figcaption>) unless caption.empty?
      html += %(</figure>)
      html
    end

    # Then handle image grouping (both standard and Cloudinary images)
    # This regex now matches both formats
    text.gsub!(/^(!\[([^\]]*)\]\(([^)]+)\)(?:\n!\[([^\]]*)\]\(([^)]+)\))+)/m) do |match|
      lines = match.strip.split("\n")

      html = %(<div class="image-group image-group-#{lines.size}">)

      lines.each do |line|
        if line =~ /!\[([^\]]*)\]\(cloudinary:([^)]+)\)/
          # It's a Cloudinary image
          alt_text = $1
          public_id = $2
          html += render_cloudinary_image(alt_text, public_id)
        elsif line =~ /!\[([^\]]*)\]\(([^)]+)\)/
          # It's a regular image
          alt_text = $1
          src = $2
          html += %(<img src="#{src}" alt="#{alt_text}" loading="lazy" />)
        end
      end

      html += %(</div>)
      html
    end

    # Finally, handle standalone Cloudinary images (not in groups)
    text.gsub!(/^!\[([^\]]*)\]\(cloudinary:([^)]+)\)$/m) do
      alt_text = $1
      public_id = $2
      render_cloudinary_image(alt_text, public_id)
    end

    text
  end

  private
    def render_cloudinary_image(alt_text, public_id)
      base_url = "https://res.cloudinary.com/blendergrid/image/upload"

      srcset = [
        "#{base_url}/f_auto,q_auto,w_580/#{public_id} 580w",
        "#{base_url}/f_auto,q_auto,w_960/#{public_id} 960w",
        "#{base_url}/f_auto,q_auto,w_1440/#{public_id} 1440w",
      ].join(", ")

      %{<img
        src="#{base_url}/f_auto,q_auto,w_960/#{public_id}"
        srcset="#{srcset}"
        sizes="(max-width: 768px) 100vw, (max-width: 1200px) 80vw, 960px"
        alt="#{alt_text}"
        loading="lazy"
      />}.gsub(/\s+/, " ")
    end
end
