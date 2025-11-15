class AccountsController < ApplicationController
  def show
    @user = Current.user
  end
end
