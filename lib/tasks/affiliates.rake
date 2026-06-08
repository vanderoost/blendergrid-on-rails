namespace :affiliates do
  desc "Set up an affiliate + landing page + page variant for an existing user"
  task create: :environment do
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

    identifier = prompt.call("User (id or email)")
    user = if identifier.match?(/\A\d+\z/)
      User.find_by(id: identifier)
    else
      User.find_by(email_address: identifier.downcase)
    end
    abort "✗ No user found for '#{identifier}'" if user.nil?
    abort "✗ #{user.email_address} already has an affiliate" if user.affiliate

    name = prompt.call("Affiliate name (e.g. Ryan King Art)")
    url = prompt.call("Affiliate URL (YouTube/site for the collab link)")

    slug = loop do
      candidate = prompt.call("Landing page slug", default: name.parameterize)
      break candidate unless LandingPage.exists?(slug: candidate)
      puts "  ↳ a landing page with that slug already exists"
    end

    reward_percent = loop do
      raw = prompt.call("Reward percent", default: "40")
      value = raw.to_i
      break value if raw.match?(/\A\d+\z/) && value.between?(1, 100)
      puts "  ↳ enter a whole number between 1 and 100"
    end

    reward_window_months = loop do
      raw = prompt.call("Reward window in months", default: "12")
      value = raw.to_i
      break value if raw.match?(/\A\d+\z/) && value.positive?
      puts "  ↳ enter a whole number of months (e.g. 12)"
    end

    note = %(In collaboration with <a href="#{url}" target="_blank" ) +
      %(class="font-semibold text-primary-600 dark:text-primary-400">) +
      %(<span aria-hidden="true" class="absolute inset-0"></span>) +
      %(#{name} <span aria-hidden="true">&rarr;</span></a>)

    sections = [
      {
        id: "heading",
        note: note,
        title: "#{name} subscribers get $20 off",
        subtitle: "Sign up to get $20 off your first cloud render.",
      },
      { id: "signup", gift: true },
      { id: "logo_cloud" },
      { id: "testimonials" },
    ]

    landing_page = nil
    ActiveRecord::Base.transaction do
      landing_page = LandingPage.create!(slug: slug)
      landing_page.page_variants.create!(sections: sections)
      Affiliate.create!(
        user: user,
        landing_page: landing_page,
        reward_percent: reward_percent,
        reward_window_months: reward_window_months,
      )
    end

    page_url = begin
      Rails.application.routes.url_helpers.landing_page_url(landing_page)
    rescue ArgumentError
      "/#{landing_page.slug}"
    end

    puts
    puts "✓ Created affiliate for #{user.email_address} (#{name})"
    puts "  Reward: #{reward_percent}% for #{reward_window_months} months"
    puts "  Landing page: #{page_url}"
  end
end
