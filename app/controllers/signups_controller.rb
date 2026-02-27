class SignupsController < ApplicationController
  allow_unauthenticated_access
  before_action :redirect_if_authenticated

  def new
    @signup = Signup.new
  end

  def create
    @signup = Signup.new(signup_params)
    if @signup.save
      render @signup
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def signup_params
    params.expect(signup: [
      :name, :email_address, :password, :password_confirmation, :terms, :gift,
      :referral_code,
    ])
  end
end
