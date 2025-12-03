namespace :affiliate_tracking do
  desc "Backfill page variant attribution for existing users"
  task backfill: :environment do
    users = User.where(page_variant_id: nil)
    total = users.count

    puts "Found #{total} users without page variant attribution"
    puts "Enqueueing attribution jobs..."

    progress = 0
    users.find_each do |user|
      AttributePageVariantJob.perform_later(user)
      progress += 1
      print "\rEnqueued: #{progress}/#{total}" if progress % 100 == 0
      sleep 5 if progress % 50 == 0
    end

    puts "\n✓ Successfully enqueued #{total} attribution jobs"
    puts "Jobs will process over the next few minutes"
  end

  desc "Report on page variant attribution status"
  task report: :environment do
    total_users = User.count
    attributed = User.where.not(page_variant_id: nil).count
    unattributed = User.where(page_variant_id: nil).count

    puts "\nPage Variant Attribution Report"
    puts "=" * 50
    puts "Total users:    #{total_users}"
    puts "Attributed:     #{attributed} (#{(attributed.to_f / total_users * 100).
      round(1)}%)"
    puts "Not attributed: #{unattributed} (#{(unattributed.to_f / total_users * 100).
      round(1)}%)"
    puts

    if attributed > 0
      puts "Attribution by Page Variant:"
      User.where.not(page_variant_id: nil)
        .group(:page_variant_id)
        .count
        .sort_by { |_, count| -count }
        .each do |variant_id, count|
          variant = PageVariant.find(variant_id)
          landing_page = variant.landing_page
          puts "  #{landing_page.slug.ljust(20)} #{count} signups"
        end
    end
  end
end
