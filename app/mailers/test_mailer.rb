class TestMailer < ApplicationMailer
  def test_email
    mail subject: "From Rails", to: "richard@blendergrid.com"
  end
end
