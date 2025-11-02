class SignupsController < ApplicationController
  allow_unauthenticated_access only: %w[new create]

  def new
    @signup = Signup.new
  end

  def create
    @signup = Signup.new signup_params
    if @signup.save
      redirect_to root_path, notice: "Check your email inbox for a verification link."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def signup_params
    params.expect(signup: [
      :name, :email_address, :password, :password_confirmation, :gift,
    ])
  end
end
