#!/usr/bin/env ruby
# script/fix_cloudinary_images.rb

ENV['RAILS_ENV'] ||= 'production'
require_relative '../config/environment'

puts "Migrating Cloudinary images to new format in #{Rails.env}..."
puts "Continue? (y/n)"
exit unless gets.chomp.downcase == 'y'

updated_count = 0
skipped_count = 0

Article.find_each do |article|
  original_body = article.body

  # Convert old format: ![alt](cloudinary:image-name)
  # To new format: ![alt](cloudinary:articles/article-slug/image-name)
  updated_body = original_body.gsub(/!\[([^\]]*)\]\(cloudinary:([^\/][^)]+)\)/) do
    alt_text = $1
    image_name = $2

    # Skip if already in new format (contains /)
    if image_name.include?('/')
      "![#{alt_text}](cloudinary:#{image_name})"
    else
      "![#{alt_text}](cloudinary:articles/#{article.slug}/#{image_name})"
    end
  end

  if updated_body != original_body
    article.update_columns(body: updated_body, updated_at: Time.current)
    puts "✅ Updated: #{article.title}"
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
