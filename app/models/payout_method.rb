class PayoutMethod
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :country, :string
  attribute :return_url, :string
  attribute :account_link_url, :string

  attr_accessor :affiliate

  def save
    ensure_account
    onboard_affiliate
  end

  private
    def ensure_account
      if affiliate.stripe_account_id.present?
        @account_id = affiliate.stripe_account_id
      else
        account = create_account
        @account_id = account.id
        affiliate.update!(stripe_account_id: @account_id)
      end
    end

    def create_account
      stripe_client.v2.core.accounts.create({
        contact_email: Current.user.email_address,
        display_name: Current.user.name,
        identity: {
          country: country || "US",
          entity_type: "individual",
        },
        configuration: {
          recipient: {
            capabilities: {
              bank_accounts: {
                local: { requested: true },
                # wire: { requested: true }, # TODO: Maybe enable later
              },
              # cards: { requested: true }, # TODO: Maybe enable later
            },
          },
        },
        include: [ "requirements", "configuration.recipient", "identity" ],
      })
    end

    def onboard_affiliate
      if affiliate.payout_onboarded_at.present?
        create_account_link("account_update")
      else
        begin
          create_account_link("account_onboarding")
        rescue Stripe::InvalidRequestError => e
          # If Stripe says account is already onboarded but we don't have it marked,
          # mark it as onboarded and create an update link instead
          if e.message.include?("already been onboarded")
            unless affiliate.payout_onboarded_at.present?
              affiliate.update(payout_onboarded_at: Time.current)
            end
            create_account_link("account_update")
          else
            raise
          end
        end
      end
      true
    end

    def create_account_link(use_case_type)
      self.account_link_url = stripe_client.v2.core.account_links.create({
        account: @account_id,
        use_case: {
          type: use_case_type,
          use_case_type.to_sym => {
            configurations: [ "recipient" ],
            return_url: return_url,
            refresh_url: return_url,
          },
        },
      }).url
    end

    def stripe_client
      @stripe_client ||= Stripe::StripeClient.new(Stripe.api_key)
    end
end
