# app/controllers/oauth/authorizations_controller.rb
class Oauth::AuthorizationsController < ApplicationController
  before_action :authenticate_user!
  before_action :validate_oauth_params, only: [:new, :create]
  before_action :find_application, only: [:new, :create]

  # GET /oauth/authorize
  # Shows authorization page where user can approve/deny access
  def new
    # Check if application is valid and active
    unless @application.active?
      render_error("Application has been revoked", :forbidden)
      return
    end

    # Validate redirect_uri only if provided
    if params[:redirect_uri].present?
      unless @application.valid_redirect_uri?(params[:redirect_uri])
        render_error("Invalid redirect_uri", :bad_request)
        return
      end
    end

    # Validate PKCE parameters
    unless valid_pkce_params?
      render_error("Invalid PKCE parameters. code_challenge and code_challenge_method are required", :bad_request)
      return
    end

    # Show authorization page
    @scopes = parse_scopes(params[:scope])
  end

  # POST /oauth/authorize
  # User approved access - generate authorization code
  def create
    if params[:authorize] == "true"
      # User approved - create authorization code
      auth_code = OauthAuthorizationCode.create!(
        oauth_application: @application,
        user: current_user,
        redirect_uri: params[:redirect_uri],
        scopes: params[:scope] || "api",
        code_challenge: params[:code_challenge],
        code_challenge_method: params[:code_challenge_method] || "S256"
      )

      # Store code and state for display
      @authorization_code = auth_code.code
      @state = params[:state]
      @application_name = @application.name

      if params[:redirect_uri].present?
        # Standard flow: Build redirect URI and auto-redirect (desktop apps)
        @redirect_uri = build_redirect_uri(params[:redirect_uri], {
          code: auth_code.code,
          state: params[:state]
        })
        # Show success page with auto-redirect
        render :success
      else
        # Manual flow: Show code on page for manual copy (CLI apps)
        @redirect_uri = nil  # No redirect - manual copy only
        render :success
      end
    else
      # User denied authorization
      if params[:redirect_uri].present?
        # Redirect with error
        redirect_uri = build_redirect_uri(params[:redirect_uri], {
          error: "access_denied",
          error_description: "User denied authorization",
          state: params[:state]
        })
        redirect_to redirect_uri, allow_other_host: true
      else
        # Show error page (no redirect for CLI apps)
        render_error("Authorization denied by user", :forbidden)
      end
    end
  end

  private

  def validate_oauth_params
    # redirect_uri is optional - supports both redirect flow (desktop) and manual code flow (CLI)
    required_params = [:client_id, :response_type, :code_challenge, :code_challenge_method]
    missing_params = required_params.select { |p| params[p].blank? }

    if missing_params.any?
      render_error("Missing required parameters: #{missing_params.join(', ')}", :bad_request)
      return
    end

    unless params[:response_type] == "code"
      render_error("Invalid response_type. Only 'code' is supported", :bad_request)
      return
    end
  end

  def find_application
    @application = OauthApplication.find_by(client_id: params[:client_id])
    unless @application
      render_error("Invalid client_id", :not_found)
    end
  end

  def valid_pkce_params?
    params[:code_challenge].present? &&
      params[:code_challenge_method].present? &&
      %w[S256 plain].include?(params[:code_challenge_method])
  end

  def parse_scopes(scope_string)
    (scope_string || "api").split(" ")
  end

  def build_redirect_uri(base_uri, params)
    return nil if base_uri.blank?

    uri = URI.parse(base_uri)
    query_params = URI.decode_www_form(uri.query || "")
    params.each do |key, value|
      query_params << [key.to_s, value.to_s] if value.present?
    end
    uri.query = URI.encode_www_form(query_params)
    uri.to_s
  end

  def render_error(message, status)
    @error_message = message
    render :error, status: status
  end
end
