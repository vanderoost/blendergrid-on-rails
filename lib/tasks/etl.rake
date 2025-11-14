# Extract old database data, Transform to new schema, Load into new database
namespace :etl do
  task all: :environment do
    Rake::Task["etl:users"].invoke
    Rake::Task["etl:landing_pages"].invoke
    Rake::Task["etl:articles"].invoke
    Rake::Task["etl:uploads"].invoke
    Rake::Task["etl:projects"].invoke
  end

  task users: :environment do
    last_updated_at = User.maximum(:updated_at) || Time.at(0)
    puts "Users table last updated at: #{last_updated_at}"

    scope = OldApp::User.where("updated_at > ?", last_updated_at)
    total_count = scope.count

    if total_count == 0
      puts "No users to migrate!"
      next
    end

    puts "Migrating #{total_count} users in #{Rails.env}…"
    deleted_count = 0
    guest_count = 0
    created_count = 0
    scope.find_each do |old_user|
      # scope.find_all do |old_user|
      if old_user.deleted_at.present?
        deleted_count += 1
      elsif old_user.password.blank?
        guest_count += 1
      else

        make_user_from_old(old_user)
        created_count += 1

        if user.render_credit_cents.nonzero? && user.saved_change_to_id_value?
          CreditEntry.create!(
            user: user,
            amount_cents: user.render_credit_cents,
            reason: :old_balance
          )
        end
      end

      processed_count = deleted_count + guest_count + created_count
      percentage = processed_count.fdiv(total_count) * 100
      print "\rProcessed #{percentage.round(1)}% - #{created_count} created |"\
        " #{guest_count} guests | #{deleted_count} deleted "
    end
    puts "- Done!"
  end

  task landing_pages: :environment do
    # First create the default home page
    landing_page = LandingPage.where(slug: "/").first_or_initialize
    landing_page.save!
    page_variant = landing_page.page_variants.first_or_initialize
    page_variant.sections = [
      {
        id: :heading,
        title: "Fast rendering for Blender",
        subtitle: "Start by uploading a .blend file.",
      },
      { id: :upload },
      { id: :logo_cloud },
      { id: :testimonials },
    ]
    page_variant.save!

    scope = OldApp::LandingPage.all
    total_count = scope.count
    puts "Migrating #{total_count} landing pages in #{Rails.env}…"

    scope.find_each do |old_landing_page|
      landing_page = LandingPage.where(slug: old_landing_page.slug).first_or_initialize

      landing_page.created_at = old_landing_page.created_at
      landing_page.save!

      heading = old_landing_page.title
      if old_landing_page.subtitle.present?
        heading += "<br/>#{old_landing_page.subtitle}"
      end

      page_variant = landing_page.page_variants.first_or_initialize
      page_variant.sections = [
        {
          id: :heading,
          title: heading,
          subtitle: "Start by uploading a .blend file.",
        },
        { id: :upload },
        { id: :logo_cloud },
        { id: :testimonials },
      ]
      page_variant.created_at = old_landing_page.created_at
      page_variant.save!

      print "\rProcessed #{old_landing_page.id} "
    end
    puts "- Done!"
  end

  task articles: :environment do
    scope = OldApp::Article.all
    total_count = scope.count
    puts "Migrating #{total_count} articles in #{Rails.env}…"

    scope.find_each do |old_article|
      article = Article.where(slug: old_article.slug).first_or_initialize

      user = User.where(id: old_article.user.id).first
      if user.nil?
        puts "No user found for article #{old_article.id}"
        make_user_from_old(old_article.user)
      end

      article.user_id = old_article.user.id
      article.title = old_article.title
      article.excerpt = old_article.summary
      article.body = update_article_body(old_article)
      article.image_url = old_article.image
      if old_article.published
        article.published_at = old_article.created_at
      end

      article.created_at = old_article.created_at
      article.save!

      print "\rProcessed #{old_article.id} "
    end
    puts "- Done!"
  end

  task uploads: :environment do
    scope = OldApp::ProjectSource.last(10)
    total_count = scope.count
    created_count = 0
    scope.find_all do |project_source|
      puts "Processing #{project_source.id}"
      puts project_source.inspect

      upload = Upload.where(id: project_source.id).first_or_initialize

      upload.user_id = project_source.user_id

      upload.save!

      created_count += 1
      percentage = created_count.fdiv(total_count) * 100
      print "\rProcessing #{percentage.round(1)}% - #{created_count} created "
    end
    puts "- Done!"
  end

  task projects: :environment do
    puts "Migrating projects in #{Rails.env}…"

    scope = OldApp::Project
      .where.not(user_id: nil)
      .where("updated_at > ?", 3.days.ago)

    # TODO: Make sure to select only rendered projects

    puts "Found #{scope.count} projects"

    scope.find_each do |old_project|
      puts "------------------------------"

      old_user = old_project.user
      if old_user.nil?
        puts "No old user found for project #{old_project.id}"
        next
      end

      if old_project.project_source.nil?
        puts "No project source found for project #{old_project.id}"
        next
      end

      unless old_project.project_events.map(&:type).include?("RENDER_ACTIVITY_SUCCESS")
        puts "Project has not finished rendering"
        next
      end

      puts "Found '#{old_project.name}' from '#{old_user.email}'"
      puts "Source: #{old_project.project_source.inspect}"

      user = User.where(email_address: old_user.email).first

      if user.nil?
        puts "No user found for email #{old_user.email}"
        next
      end

      # Create an Upload and a Project in the new database
      # Mayb also a BlenderScene?
      upload = Upload.upsert({
        uuid: old_project.project_source.uuid,
        user_id: user.id,
      }, unique_by: :uuid).first

      puts "Created upload #{upload.inspect}"

      project = Project.upsert({
        uuid: old_project.uuid,
        upload_id: upload["id"],
        name: old_project.name,
        status: "rendered",
        blend_filepath: old_project.main_blend_file,
        price_cents: old_project.price,
        deleted_at: old_project.deleted_at,
      }, unique_by: :uuid).first

      puts "Created project #{project.inspect}"
    end
  end
end

def update_article_body(article)
  updated_body = article.body.dup

  updated_body.gsub!(/!\[([^\]]*)\]\(cloudinary:([^\/][^)]+)\)/) do
    alt_text = $1
    image_name = $2

    # Skip if already in new format (contains /)
    if image_name.include?("/")
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
    "![#{caption}](https://youtu.be/#{video_id})"
  end

  # Also handle youtu.be shorthand if you use it
  updated_body.gsub!(/!\[([^\]]*)\]\(youtu\.be:([\w-]+)\)/) do
    caption = $1
    video_id = $2
    "![#{caption}](https://youtu.be/#{video_id})"
  end

  updated_body
end

def make_user_from_old(old_user)
  user = User.where(id: old_user.id).first_or_initialize

  user.name = old_user.name
  user.email_address = old_user.email
  user.password_digest = old_user.password
  user.email_address_verified = old_user.email_verified_at.present?
  user.render_credit_cents = old_user.bg_credit
  user.created_at = old_user.created_at
  user.save!
end
