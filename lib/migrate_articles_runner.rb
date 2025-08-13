# Run with: rails runner migrate_articles_runner.rb
# No additional gems needed - uses Rails' database connection

# MySQL connection configuration
# Update these with your actual MySQL database credentials
mysql_config = {
  adapter: 'mysql2',
  host: Rails.application.credentials.dig(:old_database, :host),
  username: Rails.application.credentials.dig(:old_database, :username),
  password: Rails.application.credentials.dig(:old_database, :password),
  database: Rails.application.credentials.dig(:old_database, :name),
}

def migrate_articles(mysql_config)
  puts "Starting article migration from MySQL to Rails app..."

  # Create MySQL connection using ActiveRecord
  ActiveRecord::Base.establish_connection(mysql_config)
  mysql_connection = ActiveRecord::Base.connection

  begin
    puts "✓ Connected to MySQL database"

    # Query based on your MySQL schema
    results = mysql_connection.execute(<<-SQL)
      SELECT#{' '}
        id,
        title,
        slug,
        summary,
        body,
        image,
        published,
        created_at,
        updated_at,
        team_member_id,
        views
      FROM articles#{' '}
      ORDER BY created_at ASC
    SQL

    total_count = results.count
    puts "Found #{total_count} articles to migrate"

    migrated_count = 0
    skipped_count = 0

    # Reconnect to Rails app database
    config = Rails.application.config.database_configuration[Rails.env]
    # Handle multi-database production config
    production_config = config.is_a?(Hash) && config['primary'] ? config['primary'] : config
    ActiveRecord::Base.establish_connection(production_config)

    results.each_with_index do |row, index|
      print "\rProcessing article #{index + 1}/#{total_count}..."

      begin
        # Check if article already exists (by slug or title)
        existing_article = Article.find_by(slug: row[2]) || Article.find_by(title: row[1])

        if existing_article
          skipped_count += 1
          next
        end

        # Find or create user
        user = User.find_by(id: row[9]) || User.first

        unless user
          puts "\n✗ No user found for article '#{row[1]}' (team_member_id: #{row[9]}) - skipping"
          skipped_count += 1
          next
        end

        # Convert published boolean to published_at datetime
        published_at = row[6] == 1 ? (row[7] || Time.current) : nil

        # Create new article
        article = Article.new(
          user: user,
          title: row[1],
          slug: row[2],
          excerpt: row[3],
          body: row[4],
          image_url: row[5],
          published_at: published_at,
          created_at: row[7],
          updated_at: row[8]
        )

        if article.save
          migrated_count += 1
        else
          puts "\n✗ Failed to save article '#{row[1]}': #{article.errors.full_messages.join(', ')}"
          skipped_count += 1
        end

      rescue => e
        puts "\n✗ Error processing article '#{row[1]}': #{e.message}"
        skipped_count += 1
      end
    end

    puts "\n\nMigration completed!"
    puts "✓ Successfully migrated: #{migrated_count} articles"
    puts "- Skipped: #{skipped_count} articles"

  rescue => e
    puts "\n✗ Error: #{e.message}"
  ensure
    # Restore Rails database connection
    config = Rails.application.config.database_configuration[Rails.env]
    production_config = config.is_a?(Hash) && config['primary'] ? config['primary'] : config
    ActiveRecord::Base.establish_connection(production_config)
  end
end

# Run the migration
migrate_articles(mysql_config)
