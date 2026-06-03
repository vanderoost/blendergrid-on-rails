namespace :users do
  desc "Create an invited user with gift render credit; prints a 30-day link"
  task invite: :environment do
    prompt = ->(label, default: nil) do
      suffix = default ? " [#{default}]" : ""
      loop do
        print "#{label}#{suffix}: "
        value = $stdin.gets.to_s.strip
        value = default if value.empty? && default
        return value if value.present?
        puts "  ↳ required, please try again"
      end
    end

    email = loop do
      candidate = prompt.call("Email").downcase
      if !candidate.match?(URI::MailTo::EMAIL_REGEXP)
        puts "  ↳ that doesn't look like a valid email"
      elsif User.exists?(email_address: candidate)
        puts "  ↳ a user with that email already exists"
      else
        break candidate
      end
    end

    name = prompt.call("Name")

    credit_dollars = loop do
      raw = prompt.call("Render credit in dollars", default: "50")
      break raw.to_i if raw.match?(/\A\d+\z/)
      puts "  ↳ enter a whole number of dollars (e.g. 50)"
    end

    user = User.create!(
      email_address: email,
      name: name,
      password: SecureRandom.base58(24)
    )
    user.credit_entries.create!(reason: :gift, amount_cents: credit_dollars * 100)

    link = Rails.application.routes.url_helpers
      .invite_url(user.generate_token_for(:invite))

    puts
    puts "✓ Created #{user.email_address} (#{user.name}) " \
         "with $#{credit_dollars} render credit."
    puts "  Invite link (valid 30 days):"
    puts "  #{link}"
  end
end
