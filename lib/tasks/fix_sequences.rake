namespace :db do
  desc "Reset all PostgreSQL sequences to match current max IDs"
  task reset_sequences: :environment do
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      # Get all tables with primary keys
      tables = ActiveRecord::Base.connection.tables

      tables.each do |table|
        begin
          # Get the primary key column
          pk = ActiveRecord::Base.connection.primary_key(table)
          next unless pk

          # Get the sequence name
          sequence = "#{table}_#{pk}_seq"

          # Check if sequence exists
          seq_exists = ActiveRecord::Base.connection.execute(
            "SELECT 1 FROM pg_sequences WHERE schemaname = 'public'
             AND sequencename = '#{sequence}'"
          ).any?

          next unless seq_exists

          # Get max ID
          max_id = ActiveRecord::Base.connection.execute(
            "SELECT COALESCE(MAX(#{pk}), 0) + 1 AS max_id FROM #{table}"
          ).first['max_id']

          # Reset sequence
          ActiveRecord::Base.connection.execute(
            "SELECT setval('#{sequence}', #{max_id}, false)"
          )

          puts "✓ Reset #{table}.#{pk} sequence to #{max_id}"
        rescue => e
          puts "⚠ Skipped #{table}: #{e.message}"
        end
      end

      puts "\n✅ All sequences have been reset!"
    else
      puts "This task only works with PostgreSQL databases"
    end
  end
end
