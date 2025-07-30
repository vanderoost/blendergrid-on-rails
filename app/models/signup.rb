class Signup
  include ActiveModel::Model
  include ActiveModel::Attributes
  include EmailValidatable

  attribute :email_address, :string
  attribute :password, :string

  validates :email_address, presence: true, length: { maximum: 255 }
  validates :email_address, format: EmailValidatable::VALID_EMAIL_REGEX
  validates :password, length: 8..72, confirmation: true

  def save
    if valid?
      user = User.new(email_address:, password:)
      if user.save
        EmailAddressVerification.new(user).save
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
end
