class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to @user, notice: "Welcome to Blendergrid!"
    else
    render :new, status: :unprocessable_entity,
        alert: @user.errors.full_messages.to_sentence
    end
  end

  private
    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end
end
