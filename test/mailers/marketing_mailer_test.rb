require "test_helper"

class MarketingMailerTest < ActionMailer::TestCase
  setup do
    @subscriber = subscribers(:gary_subscriber)  # user-linked
    @guest = subscribers(:newsletter_guest)
  end

  test "announcement sends from the marketing subdomain with the SES config set" do
    mail = MarketingMailer.announcement(@subscriber)

    assert_equal [ "richard@mail.blendergrid.com" ], mail.from
    assert_equal "marketing", mail["X-SES-CONFIGURATION-SET"].value
    assert_equal "What's new at Blendergrid", mail.subject
    assert_equal [ @subscriber.email_address ], mail.to
  end

  test "announcement includes one-click unsubscribe headers" do
    mail = MarketingMailer.announcement(@subscriber)

    assert_match %r{/unsubscribe/}, mail["List-Unsubscribe"].value
    assert_equal "List-Unsubscribe=One-Click", mail["List-Unsubscribe-Post"].value
  end

  test "announcement includes a visible unsubscribe link in the body" do
    mail = MarketingMailer.announcement(@subscriber)

    assert_match %r{/unsubscribe/}, mail.html_part.body.to_s
    assert_match %r{/unsubscribe/}, mail.text_part.body.to_s
  end

  test "user-linked subscriber gets a magic-login link" do
    mail = MarketingMailer.announcement(@subscriber)

    assert_match %r{session_token=}, mail.html_part.body.to_s
  end

  test "guest subscriber gets no magic-login link" do
    mail = MarketingMailer.announcement(@guest)

    assert_equal [ @guest.guest_email_address ], mail.to
    assert_no_match %r{session_token=}, mail.html_part.body.to_s
  end

  test "announcement is a no-op for unsubscribed subscribers" do
    @subscriber.unsubscribe!

    assert_no_emails do
      MarketingMailer.announcement(@subscriber).deliver_now
    end
  end

  test "drip emails send from the marketing subdomain with unsubscribe headers" do
    mail = MarketingMailer.drip_adaptive_sampling(@subscriber)

    assert_equal [ "richard@mail.blendergrid.com" ], mail.from
    assert_equal "marketing", mail["X-SES-CONFIGURATION-SET"].value
    assert_equal [ @subscriber.email_address ], mail.to
    assert_match %r{/unsubscribe/}, mail["List-Unsubscribe"].value
    assert_equal "List-Unsubscribe=One-Click", mail["List-Unsubscribe-Post"].value
  end

  test "every drip step has a sendable mailer method and templates" do
    MarketingMailer::DRIP_SEQUENCE.each do |step|
      mail = MarketingMailer.public_send(step[:action], @subscriber)

      assert mail.subject.present?, "#{step[:action]} is missing a subject"
      assert_match %r{/unsubscribe/}, mail.html_part.body.to_s
      assert_match %r{/unsubscribe/}, mail.text_part.body.to_s
    end
  end

  test "drip emails are a no-op for unsubscribed subscribers" do
    @subscriber.unsubscribe!

    assert_no_emails do
      MarketingMailer.drip_adaptive_sampling(@subscriber).deliver_now
    end
  end
end
