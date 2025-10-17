# app/controllers/api/base_controller.rb
class Api::BaseController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate_api_user!

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

  private

  def authenticate_api_user!
    authenticate_or_request_with_http_token do |token, options|
      # Try OAuth access token first
      oauth_token = OauthAccessToken.includes(:user).find_by(token: token)

      if oauth_token
        # Check if OAuth token is active
        if oauth_token.active?
          @current_api_user = oauth_token.user
          @current_oauth_token = oauth_token
          # Update last used timestamp
          oauth_token.touch_last_used!
        else
          @token_status = oauth_token.revoked? ? "revoked" : "expired"
        end
      else
        # Fall back to legacy API token
        api_token = ApiToken.includes(:user).find_by(token: token)

        if api_token
          # Check if token is active
          if api_token.active?
            @current_api_user = api_token.user
            @current_api_token = api_token
            # Update last used timestamp
            api_token.touch_last_used!
          else
            @token_status = api_token.revoked? ? "revoked" : "expired"
          end
        end
      end

      # CRITICAL: Always return true to prevent auto-render by authenticate_or_request_with_http_token
      # We handle all error cases manually below
      true
    end

    # Now manually handle all error cases with explicit renders
    # CRITICAL: Only render if authenticate_or_request_with_http_token didn't already render
    # (it auto-renders when no Authorization header is present)
    return if performed?

    if @token_status
      render json: { error: "API token has been #{@token_status}" }, status: :unauthorized
      return
    elsif !@current_api_user
      render json: { error: "Invalid or missing API token" }, status: :unauthorized
      return
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
