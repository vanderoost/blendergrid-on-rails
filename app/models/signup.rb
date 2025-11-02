class Signup
  GIFT_CENTS = 2000

  include ActiveModel::Model
  include ActiveModel::Attributes
  include EmailValidatable

  attribute :name, :string
  attribute :email_address, :string
  attribute :password, :string
  attribute :gift, :boolean

  validates :name, presence: true, length: { maximum: 255 }
  validates :email_address, presence: true, length: { maximum: 255 }
  validates :email_address, format: EmailValidatable::VALID_EMAIL_REGEX
  validates :password, length: 8..72, confirmation: true

  def save
    puts "GIFT: #{gift.inspect}"

    if valid?
      user = User.new(name:, email_address:, password:)
      if user.save
        EmailAddressVerification.new(user).save
        give_credit user if gift
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
    def give_credit(user)
      puts "GIVING CREDIT GIFT TO: #{user.name}"
      CreditEntry.create(user: user, amount_cents: GIFT_CENTS, reason: :gift)
    end
end
