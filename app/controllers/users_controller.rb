class UsersController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]

  def new
    @user = User.new
  end

  def create
    @user = User.where(email: user_params[:email]).first

    if @user
      redirect_to new_registration_path, alert: "You already have an account!"
    else
      @user = User.new(user_params)
      if @user.save
         start_new_session_for @user
         redirect_to root_path, notice: "Welcome to Blendergrid!"
      else
        flash[:alert] = @user.errors.full_messages.join("\n")
        render :new, status: :unprocessable_entity
      end
    end
  end

  def show
    @user = User.find(params[:id])
    render plain: "veve is cute :3"
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
