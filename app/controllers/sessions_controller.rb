class SessionsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.authenticate_by(email: params[:email], password: params[:password])
    if @user
      login @user
      redirect_to dashboard_path, notice: "Welcome back!"
    else
      flash.now[:alert] = "Invalid email or password"
      @user = User.new(email: params[:email])
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    logout
    redirect_to root_path, notice: "Logged out successfully", status: :see_other
  end

  def omniauth
    auth = request.env['omniauth.auth']
    user = User.from_omniauth(auth)

    if user.persisted?
      # Create organization if user doesn't have one
      if user.organizations.empty?
        organization = Organization.create!(
          name: "#{user.full_name}'s Organization",
          slug: user.email.split('@').first.parameterize
        )
        Membership.create!(
          user: user,
          organization: organization,
          role: 'owner'
        )
      end

      login(user)
      redirect_to dashboard_path, notice: "Welcome #{user.first_name}!"
    else
      flash[:alert] = "There was an error signing you in through Google"
      redirect_to login_path
    end
  end
end