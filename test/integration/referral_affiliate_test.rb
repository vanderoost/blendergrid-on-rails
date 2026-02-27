require "test_helper"

class ReferralAffiliateTest < ActionDispatch::IntegrationTest
  test "signing up with a valid referral code attributes the referral" do
    affiliate = affiliates(:gary)

    assert_difference "User.count", 1 do
      post signups_url, params: { signup: {
        name: "New User",
        email_address: "newuser@example.com",
        password: "password",
        password_confirmation: "password",
        terms: "1",
        referral_code: affiliate.referral_code,
      } }
    end

    user = User.find_by(email_address: "newuser@example.com")
    assert_equal affiliate, user.referring_affiliate
  end

  test "signing up with an invalid referral code skips attribution" do
    assert_difference "User.count", 1 do
      post signups_url, params: { signup: {
        name: "New User",
        email_address: "newuser@example.com",
        password: "password",
        password_confirmation: "password",
        terms: "1",
        referral_code: "notacode",
      } }
    end

    user = User.find_by(email_address: "newuser@example.com")
    assert_nil user.referring_affiliate
  end

  test "signing up without a referral code skips attribution" do
    assert_difference "User.count", 1 do
      post signups_url, params: { signup: {
        name: "New User",
        email_address: "newuser@example.com",
        password: "password",
        password_confirmation: "password",
        terms: "1",
      } }
    end

    user = User.find_by(email_address: "newuser@example.com")
    assert_nil user.referring_affiliate
  end

  test "attribute_page_variant_job skips users attributed via referral code" do
    affiliate = affiliates(:gary)
    user = users(:billy)
    user.update_column(:referring_affiliate_id, affiliate.id)

    perform_enqueued_jobs(only: AttributePageVariantJob) do
      AttributePageVariantJob.perform_later(user)
    end

    assert_nil user.reload.page_variant_id
  end

  test "user gets a referral affiliate after their first topup reaches $10" do
    user = users(:billy)
    assert_nil user.affiliate

    CreditEntry.create!(user: user, amount_cents: 500, reason: :topup)
    assert_nil user.reload.affiliate, "Should not create affiliate below threshold"

    CreditEntry.create!(user: user, amount_cents: 600, reason: :topup)
    user.reload
    assert_not_nil user.affiliate
    assert_not_nil user.affiliate.referral_code
    assert_nil user.affiliate.landing_page_id
  end

  test "user gets a referral affiliate after a paid order reaches $10" do
    user = users(:billy)
    assert_nil user.affiliate

    Order.insert({
      user_id: user.id, cash_cents: 1500, credit_cents: 0,
      created_at: Time.current, updated_at: Time.current,
    })
    order = Order.where(user: user).last
    assert_nil user.reload.affiliate

    order.update!(stripe_payment_intent_id: "pi_test_123")
    user.reload
    assert_not_nil user.affiliate
    assert_not_nil user.affiliate.referral_code
  end

  test "existing influencer affiliate is not replaced when user pays" do
    user = users(:richard)

    assert_no_difference "Affiliate.count" do
      CreditEntry.create!(user: user, amount_cents: 5000, reason: :topup)
    end

    assert_not_nil user.reload.affiliate.landing_page_id
  end
end
