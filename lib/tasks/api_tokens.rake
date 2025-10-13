namespace :api_tokens do
  desc "Generate a new API token"
  task :generate, [ :name ] => :environment do |_t, args|
    name = args[:name] || "API Token"

    api_token = ApiToken.new(name: name)

    if api_token.save
      puts "API Token generated successfully!"
      puts "Name: #{api_token.name}"
      puts "Token (save this, it won't be shown again):"
      puts api_token.token
    else
      puts "Error creating API token:"
      api_token.errors.full_messages.each do |msg|
        puts "  - #{msg}"
      end
      exit 1
    end
  end

  desc "List all API tokens"
  task list: :environment do
    tokens = ApiToken.order(created_at: :desc)

    if tokens.empty?
      puts "No API tokens found."
      exit
    end

    puts "API Tokens"
    printf(
      "%-5s %-25s %-30s %-20s %-20s\n",
      "ID",
      "Name",
      "Last Used",
      "Created"
    )

    tokens.each do |token|
      printf(
        "%-5s %-25s %-30s %-20s %-20s\n",
        token.id,
        token.name.to_s.truncate(25),
        token.last_used_at&.strftime("%Y-%m-%d %H:%M") || "Never",
        token.created_at.strftime("%Y-%m-%d %H:%M")
      )
    end
    puts "\n"
  end

  desc "Revoke an API token by ID"
  task :revoke, [ :id ] => :environment do |_t, args|
    unless args[:id]
      puts "Error: Please provide a token ID"
      puts "Usage: rails api_tokens:revoke[TOKEN_ID]"
      exit 1
    end

    token = ApiToken.find_by(id: args[:id])

    unless token
      puts "Error: Token with ID #{args[:id]} not found"
      exit 1
    end

    token.destroy
    puts "API token '#{token.name}' (ID: #{token.id}) has been revoked."
  end
end
