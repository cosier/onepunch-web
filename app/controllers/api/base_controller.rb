# app/controllers/api/base_controller.rb
class Api::BaseController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate_api_user!

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

  private

  def authenticate_api_user!
    authenticate_or_request_with_http_token do |token, options|
      @current_api_user = User.find_by(api_token: token)
    end

    unless @current_api_user
      render json: { error: "Invalid or missing API token" }, status: :unauthorized
    end
  end

  def current_api_user
    @current_api_user
  end

  def current_organization
    @current_organization ||= current_api_user&.current_organization
  end

  # Get organization from header or use user's current organization
  def organization_from_request
    org_id = request.headers["X-Organization-ID"]
    if org_id.present?
      org = current_api_user.organizations.find_by(id: org_id)
      return org if org
    end
    current_organization
  end

  def not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end

  def unprocessable_entity(exception)
    render json: {
      error: exception.message,
      details: exception.record&.errors&.full_messages
    }, status: :unprocessable_entity
  end

  def render_error(message, status: :bad_request)
    render json: { error: message }, status: status
  end

  def render_success(data, status: :ok, meta: {})
    response = { data: data }
    response[:meta] = meta if meta.any?
    render json: response, status: status
  end
end
