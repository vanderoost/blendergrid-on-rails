class TransactionsController < ApplicationController
  def index
    @transactions = Current.user.credit_entries
      .where(created_at: 60.days.ago..)
      .where(reason: :topup)
      .order(created_at: :desc)
  end
end
