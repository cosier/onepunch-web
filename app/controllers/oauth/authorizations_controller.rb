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

    # Validate redirect_uri
    unless @application.valid_redirect_uri?(params[:redirect_uri])
      render_error("Invalid redirect_uri", :bad_request)
      return
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

      # Build redirect URI for deep link
      @redirect_uri = build_redirect_uri(params[:redirect_uri], {
        code: auth_code.code,
        state: params[:state]
      })

      # Store code and state for display
      @authorization_code = auth_code.code
      @state = params[:state]
      @application_name = @application.name

      # Show success page with code and auto-redirect
      render :success
    else
      # User denied - redirect with error
      redirect_uri = build_redirect_uri(params[:redirect_uri], {
        error: "access_denied",
        error_description: "User denied authorization",
        state: params[:state]
      })
      redirect_to redirect_uri, allow_other_host: true
    end
  end

  private

  def validate_oauth_params
    required_params = [:client_id, :redirect_uri, :response_type, :code_challenge, :code_challenge_method]
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
