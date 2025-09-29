class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user, :logged_in?, :current_organization

  private

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def current_organization
    @current_organization ||= current_user&.current_organization
  end

  def authenticate_user!
    unless logged_in?
      redirect_to login_path, alert: "Please log in to continue"
    end
  end

  def login(user)
    session[:user_id] = user.id
    user.update(last_sign_in_at: Time.current)
  end

  def logout
    session.delete(:user_id)
    @current_user = nil
  end
end
