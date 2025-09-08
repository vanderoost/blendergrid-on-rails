class MarkdownRenderer < Redcarpet::Render::HTML
  CLOUDINARY_BASE_URL = "https://res.cloudinary.com/blendergrid/image/upload"
  GROUP_IMAGE_WIDTHS = [ 400, 600, 800 ]
  SINGLE_IMAGE_WIDTHS = [ 580, 960, 1440, 1920 ]
  YOUTUBE_EMBED_PATTERN = %r{
    !\[([^\]]*)\]
    \(
      (https?://(?:www\.)?
        (?:youtube\.com/watch\?v=|youtu\.be/)
        ([\w-]+)
        [^)]*)
    \)
  }x
  VIMEO_EMBED_PATTERN = %r{
    !\[([^\]]*)\]
    \(
      (https?://(?:www\.)?
        vimeo\.com/
        (\d+)
        [^)]*)
    \)
  }x

  def preprocess(text)
    text = process_youtube_embeds(text)
    text = process_vimeo_embeds(text)
    text = process_image_groups(text)
    text = process_standalone_cloudinary_images(text)
    text
  end

  private
    def process_youtube_embeds(text)
      text.gsub(YOUTUBE_EMBED_PATTERN) do
        create_video_figure("https://www.youtube.com/embed/#{$3}", $1)
      end
    end

    def process_vimeo_embeds(text)
      text.gsub(VIMEO_EMBED_PATTERN) do
        create_video_figure("https://player.vimeo.com/video/#{$3}", $1)
      end
    end

    def create_video_figure(embed_url, caption)
      <<~HTML.gsub(/\s+/, " ")
        <figure>
          <div class="relative aspect-video overflow-hidden">
            <iframe src="#{embed_url}"
              class="absolute inset-0 w-full h-full"
              frameborder="0"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
              allowfullscreen></iframe>
          </div>
          #{caption.empty? ? "" : %(<figcaption class="text-center">#{caption}</figcaption>)}
        </figure>
      HTML
    end

    # Image group processing
    def process_image_groups(text)
      pattern = /^(!\[([^\]]*)\]\(([^)]+)\)(?:\n!\[([^\]]*)\]\(([^)]+)\))+)/m

      text.gsub(pattern) do |match|
        images = extract_images(match)
        create_image_grid(images)
      end
    end

    def extract_images(markdown_block)
      markdown_block.strip.split("\n").map do |line|
        case line
        when /!\[([^\]]*)\]\(cloudinary:([^)]+)\)/
          { type: :cloudinary, alt: $1, id: $2 }
        when /!\[([^\]]*)\]\(([^)]+)\)/
          { type: :standard, alt: $1, src: $2 }
        end
      end.compact
    end

    def create_image_grid(images)
      return create_captioned_pair(images) if images.size == 2

      <<~HTML.gsub(/\s+/, " ")
        <figure>
          <div class="#{grid_class_for(images.size)}">
            #{images.map { |img| render_grid_image(img) }.join}
          </div>
        </figure>
      HTML
    end

    def create_captioned_pair(images)
      <<~HTML.gsub(/\s+/, " ")
        <figure>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            #{images.map { |img| render_captioned_image(img) }.join}
          </div>
        </figure>
      HTML
    end

    def render_captioned_image(image)
      <<~HTML.gsub(/\s+/, " ")
        <div>
          #{render_grid_image(image)}
          #{image[:alt].empty? ? "" : %(<figcaption class="text-center">#{image[:alt]}</figcaption>)}
        </div>
      HTML
    end

    def render_grid_image(image)
      case image[:type]
      when :cloudinary
        cloudinary_image_tag(image[:id], image[:alt], grouped: true)
      when :standard
        %(<img src="#{image[:src]}" alt="#{image[:alt]}" loading="lazy"
      class="w-full h-auto" />)
      end
    end

    def grid_class_for(count)
      case count
      when 3 then "grid grid-cols-1 md:grid-cols-3 gap-3"
      when 4 then "grid grid-cols-2 gap-3"
      else        "grid grid-cols-2 md:grid-cols-3 gap-3"
      end
    end

    # Standalone Cloudinary images
    def process_standalone_cloudinary_images(text)
      text.gsub(/^!\[([^\]]*)\]\(cloudinary:([^)]+)\)$/m) do
        alt_text, public_id = $1, $2

        <<~HTML.gsub(/\s+/, " ")
          <figure>
            #{cloudinary_image_tag(public_id, alt_text, grouped: false)}
            #{alt_text.empty? ? "" : %(<figcaption class="text-center">#{alt_text}</figcaption>)}
          </figure>
        HTML
      end
    end

    # Cloudinary helper
    def cloudinary_image_tag(public_id, alt_text, grouped:)
      widths = grouped ? GROUP_IMAGE_WIDTHS : SINGLE_IMAGE_WIDTHS
      srcset = widths.map { |w|
   "#{CLOUDINARY_BASE_URL}/f_auto,q_auto,w_#{w}/#{public_id} #{w}w" }.join(", ")

      sizes = grouped ?
        "(max-width: 768px) 100vw, (max-width: 1024px) 50vw, 33vw" :
        "(max-width: 768px) 100vw, (max-width: 1536px) 80vw, 768px"

      classes = grouped ? "max-h-64" : "max-h-80"

      <<~HTML.gsub(/\s+/, " ")
        <img
          src="#{CLOUDINARY_BASE_URL}/f_auto,q_auto,w_960/#{public_id}"
          srcset="#{srcset}"
          sizes="#{sizes}"
          alt="#{alt_text}"
          loading="lazy"
          class="#{classes} w-full object-contain h-auto not-prose"
        />
      HTML
    end
end
