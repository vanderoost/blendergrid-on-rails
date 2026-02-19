class Email < ApplicationRecord
  validates :email_address, :mailer_class, :action, presence: true
end
