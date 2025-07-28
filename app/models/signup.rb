class Signup
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email_address, :string
  attribute :password, :string

  validates :email_address, presence: true
  validates :password, length: 8..72, confirmation: true

  def save
    if valid?
      user = User.new(email_address:, password:)
      if user.save
        send_verification_email_to user
        true
      else
        user.errors.each do |error|
          errors.add(error.attribute, error.message)
        end
        false
      end
    end
  end

  def model_name
    ActiveModel::Name.new(self, nil, self.class.name)
  end

  private
    def send_verification_email_to(user)
      EmailAddressVerificationMailer.verify_email_address(user).deliver_later
    end
end
