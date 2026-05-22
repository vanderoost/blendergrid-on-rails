# Preview all emails at http://localhost:3000/rails/mailers/onboarding_mailer
class OnboardingMailerPreview < ActionMailer::Preview
  def signed_up_without_uploads
    OnboardingMailer.signed_up_without_uploads(user)
  end

  def signed_up_without_benchmarks
    OnboardingMailer.signed_up_without_benchmarks(user)
  end

  def signed_up_without_renders
    OnboardingMailer.signed_up_without_renders(user)
  end

  private
    # A real (persisted) user so generate_token_for(:session) works in the
    # preview links. Falls back to a built one if the dev db is empty.
    def user
      User.first || User.new(
        first_name: "Alex", email_address: "alex@example.com"
      )
    end
end
