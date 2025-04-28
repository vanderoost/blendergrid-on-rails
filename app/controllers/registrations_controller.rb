 class RegistrationsController < ApplicationController
   allow_unauthenticated_access

   def new
     @user = User.new
   end

   def create
     @user = User.where(email_address: user_params[:email_address]).first
     Rails.logger.info "User: " + @user.inspect
     if @user
       if @user.password_digest
         redirect_to new_registration_path, alert: "You already have an account!"
       else
         @user.update(user_params)
         register_user
       end
     else
       @user = User.new(user_params)
       if @user.save
         register_user
       else
         flash[:alert] = @user.errors.full_messages.join("\n")
         render :new
       end
     end
   end

   private

   def register_user
     # TODO: Email confirmations (maybe use devise?)
     start_new_session_for @user
     redirect_to root_path, notice: "Welcome to Blendergrid!"

     # TODO: Associate any guest-projects from the session with the user
   end

   def user_params
     params.require(:user).permit(:email_address, :password, :password_confirmation)
   end
 end
