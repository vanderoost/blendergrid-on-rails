require "test_helper"

class MarketingMailerTest < ActionMailer::TestCase
  test "announcement sends from the marketing subdomain with the SES config set" do
    mail = MarketingMailer.announcement(users(:gary))

    assert_equal [ "richard@mail.blendergrid.com" ], mail.from
    assert_equal "marketing", mail["X-SES-CONFIGURATION-SET"].value
    assert_equal "What's new at Blendergrid", mail.subject
  end

  test "announcement includes one-click unsubscribe headers" do
    mail = MarketingMailer.announcement(users(:gary))

    assert_match %r{/unsubscribe/}, mail["List-Unsubscribe"].value
    assert_equal "List-Unsubscribe=One-Click", mail["List-Unsubscribe-Post"].value
  end

  test "announcement includes a visible unsubscribe link in the body" do
    mail = MarketingMailer.announcement(users(:gary))

    assert_match %r{/unsubscribe/}, mail.html_part.body.to_s
    assert_match %r{/unsubscribe/}, mail.text_part.body.to_s
  end

  test "announcement is a no-op for unsubscribed users" do
    user = users(:gary)
    user.unsubscribe_from_marketing!

    assert_no_emails do
      MarketingMailer.announcement(user).deliver_now
    end
  end
end
