# app/controllers/oauth/tokens_controller.rb
class Oauth::TokensController < ActionController::API
  # POST /oauth/token
  # Exchange authorization code for access token
  def create
    case params[:grant_type]
    when "authorization_code"
      handle_authorization_code_grant
    when "refresh_token"
      handle_refresh_token_grant
    else
      render_error("Unsupported grant_type", :bad_request)
    end
  end

  private

  def handle_authorization_code_grant
    # Validate required parameters
    unless valid_authorization_code_params?
      render_error("Missing required parameters", :bad_request)
      return
    end

    # Find application
    application = OauthApplication.find_by(client_id: params[:client_id])
    unless application
      render_error("Invalid client_id", :unauthorized)
      return
    end

    # Verify client_secret for confidential clients
    if application.confidential && application.client_secret != params[:client_secret]
      render_error("Invalid client_secret", :unauthorized)
      return
    end

    # Find authorization code
    auth_code = OauthAuthorizationCode.includes(:user).find_by(code: params[:code])
    unless auth_code
      render_error("Invalid authorization code", :bad_request)
      return
    end

    # Verify authorization code belongs to this application
    unless auth_code.oauth_application_id == application.id
      render_error("Authorization code does not belong to this application", :bad_request)
      return
    end

    # Check if code is active
    unless auth_code.active?
      status = auth_code.revoked? ? "revoked" : "expired"
      render_error("Authorization code has been #{status}", :bad_request)
      return
    end

    # Validate redirect_uri matches (only for desktop flow - CLI flow has nil redirect_uri)
    if auth_code.redirect_uri.present?
      unless auth_code.redirect_uri == params[:redirect_uri]
        render_error("Invalid redirect_uri", :bad_request)
        return
      end
    end

    # Validate PKCE code_verifier
    unless auth_code.valid_code_verifier?(params[:code_verifier])
      render_error("Invalid code_verifier", :bad_request)
      return
    end

    # All validations passed - create access token
    access_token = OauthAccessToken.create!(
      oauth_application: application,
      user: auth_code.user,
      scopes: auth_code.scopes
    )

    # Revoke the authorization code (one-time use)
    auth_code.revoke!

    # Return access token
    render json: access_token.as_json, status: :ok
  end

  def handle_refresh_token_grant
    # Validate required parameters
    unless params[:refresh_token].present?
      render_error("Missing refresh_token parameter", :bad_request)
      return
    end

    # Find application
    application = OauthApplication.find_by(client_id: params[:client_id])
    unless application
      render_error("Invalid client_id", :unauthorized)
      return
    end

    # Verify client_secret for confidential clients
    if application.confidential && application.client_secret != params[:client_secret]
      render_error("Invalid client_secret", :unauthorized)
      return
    end

    # Find existing token by refresh_token
    existing_token = OauthAccessToken.includes(:user).find_by(refresh_token: params[:refresh_token])
    unless existing_token
      render_error("Invalid refresh_token", :bad_request)
      return
    end

    # Verify token belongs to this application
    unless existing_token.oauth_application_id == application.id
      render_error("Refresh token does not belong to this application", :bad_request)
      return
    end

    # Check if token is revoked
    if existing_token.revoked?
      render_error("Refresh token has been revoked", :bad_request)
      return
    end

    # Revoke old token
    existing_token.revoke!

    # Create new access token with same scopes
    new_token = OauthAccessToken.create!(
      oauth_application: application,
      user: existing_token.user,
      scopes: existing_token.scopes
    )

    # Return new access token
    render json: new_token.as_json, status: :ok
  end

  def valid_authorization_code_params?
    params[:code].present? &&
      params[:client_id].present? &&
      params[:code_verifier].present?
    # Note: redirect_uri is optional (CLI flow doesn't use it)
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
