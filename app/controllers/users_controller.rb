class UsersController < ApplicationController
  before_action :set_user, only: %i[ show update ]

  def show
  end

  def update
    if @user.update(user_params)
      redirect_to account_path, notice: "Personal information was successfully updated."
    else
      render "accounts/show", status: :unprocessable_entity
    end
  end

  private
    def set_user
      @user = User.find(params.expect(:id))
    end

    def user_params
      params.expect(user: [ :name, :email_address ])
    end
end
