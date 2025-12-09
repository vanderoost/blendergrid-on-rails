class PayoutMethodsController < ApplicationController
  def create
    @payout_method = PayoutMethod.new(payout_method_params)

    if @payout_method.save
      redirect_to_safe_url @payout_method.account_link_url
    else
      puts "PAYOUT METHOD COULD NOT BE SAVED"
      redirect_to :account, alert: "Sorry, we couldn't create your payout method."\
        " Please try again or ask us for help."
    end
  end

  private
    def payout_method_params
      params.permit(:country).merge(
        affiliate: Current.user&.affiliate,
        return_url: account_url,
      )
    end
end
