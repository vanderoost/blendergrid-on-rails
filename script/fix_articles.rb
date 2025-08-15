#!/usr/bin/env ruby

ENV['RAILS_ENV'] ||= 'production'
require_relative '../config/environment'

puts "Migrating Cloudinary images and video embeds in #{Rails.env}..."
puts "Continue? (y/n)"
exit unless gets.chomp.downcase == 'y'

updated_count = 0
skipped_count = 0

Article.find_each do |article|
  original_body = article.body
  updated_body = original_body.dup

  # Convert old format: ![alt](cloudinary:image-name)
  # To new format: ![alt](cloudinary:articles/article-slug/image-name)
  updated_body.gsub!(/!\[([^\]]*)\]\(cloudinary:([^\/][^)]+)\)/) do
    alt_text = $1
    image_name = $2

    # Skip if already in new format (contains /)
    if image_name.include?('/')
      "![#{alt_text}](cloudinary:#{image_name})"
    else
      "![#{alt_text}](cloudinary:articles/#{article.slug}/#{image_name})"
    end
  end

  # Convert: ![caption](vimeo:1073652265) -> ![caption](https://vimeo.com/1073652265)
  updated_body.gsub!(/!\[([^\]]*)\]\(vimeo:(\d+)\)/) do
    caption = $1
    video_id = $2
    "![#{caption}](https://vimeo.com/#{video_id})"
  end

  # Convert: ![caption](youtube:VIDEO_ID) -> ![caption](https://www.youtube.com/watch?v=VIDEO_ID)
  updated_body.gsub!(/!\[([^\]]*)\]\(youtube:([\w-]+)\)/) do
    caption = $1
    video_id = $2
    "![#{caption}](https://www.youtube.com/watch?v=#{video_id})"
  end

  # Also handle youtu.be shorthand if you use it
  updated_body.gsub!(/!\[([^\]]*)\]\(youtu\.be:([\w-]+)\)/) do
    caption = $1
    video_id = $2
    "![#{caption}](https://youtu.be/#{video_id})"
  end

  if updated_body != original_body
    article.update_columns(body: updated_body, updated_at: Time.current)
    puts "✅ Updated: #{article.title}"

    # Show what changed for verification
    if original_body.include?('cloudinary:')
      puts "   • Migrated Cloudinary images"
    end
    if original_body.include?('vimeo:')
      puts "   • Converted Vimeo embeds"
    end
    if original_body.include?('youtube:') || original_body.include?('youtu.be:')
      puts "   • Converted YouTube embeds"
    end

    updated_count += 1

    # Clear cache
    # Rails.cache.delete("article/full/#{article.slug}")
  else
    puts "⏭️  Skipped: #{article.title}"
    skipped_count += 1
  end
end

puts "\n📊 Summary:"
puts "   Updated: #{updated_count} articles"
puts "   Skipped: #{skipped_count} articles"
