class PasswordSetupController < ApplicationController
  before_action :authenticate_user!
  before_action :check_if_password_already_set

  def new
    @user = current_user
  end

  def create
    @user = current_user

    if @user.update(password_params.merge(password_auto_generated: false))
      flash[:notice] = "Password successfully set! You can now login with your email and password."
      redirect_to settings_account_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def check_if_password_already_set
    if current_user.has_password_set?
      redirect_to settings_account_path, alert: "You already have a password set."
    end
  end
end