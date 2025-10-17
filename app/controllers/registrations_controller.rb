class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      # Create a default organization for the user
      organization = Organization.create!(
        name: "#{@user.full_name}'s Organization",
        slug: @user.email.split('@').first.parameterize
      )

      # Create membership
      Membership.create!(
        user: @user,
        organization: organization,
        role: 'owner'
      )

      login @user
      redirect_to dashboard_path, notice: "Welcome to OnePunch!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :password, :password_confirmation)
  end
end