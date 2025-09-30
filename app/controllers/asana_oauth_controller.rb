class AsanaOauthController < ApplicationController
  before_action :authenticate_user!

  def authorize
    # Redirect to Asana OAuth authorization URL
    redirect_to asana_authorization_url, allow_other_host: true
  end

  def callback
    # Exchange authorization code for access token
    token_response = exchange_code_for_token(params[:code])

    if token_response[:access_token]
      # Fetch workspace info
      workspace = fetch_default_workspace(token_response[:access_token])

      # Create or update credential
      current_user.create_asana_credential!(
        access_token: token_response[:access_token],
        refresh_token: token_response[:refresh_token],
        expires_at: Time.current + token_response[:expires_in].to_i.seconds,
        workspace_gid: workspace&.dig('gid'),
        workspace_name: workspace&.dig('name')
      )

      redirect_to settings_integrations_asana_path, notice: "Asana connected successfully!"
    else
      redirect_to settings_integrations_asana_path, alert: "Failed to connect Asana. Please try again."
    end
  rescue => e
    Rails.logger.error "Asana OAuth error: #{e.message}"
    redirect_to settings_integrations_asana_path, alert: "An error occurred while connecting Asana."
  end

  private

  def asana_authorization_url
    client_id = ENV['ASANA_CLIENT_ID'] || Rails.application.credentials.dig(:asana, :client_id)
    Rails.logger.info "Asana OAuth - client_id: #{client_id}"

    params = {
      client_id: client_id,
      redirect_uri: asana_oauth_callback_url,
      response_type: 'code',
      state: SecureRandom.hex(16)
    }

    url = "https://app.asana.com/-/oauth_authorize?#{params.to_query}"
    Rails.logger.info "Asana OAuth - authorization URL: #{url}"
    url
  end

  def exchange_code_for_token(code)
    response = HTTParty.post('https://app.asana.com/-/oauth_token',
      body: {
        grant_type: 'authorization_code',
        client_id: ENV['ASANA_CLIENT_ID'] || Rails.application.credentials.dig(:asana, :client_id),
        client_secret: ENV['ASANA_CLIENT_SECRET'] || Rails.application.credentials.dig(:asana, :client_secret),
        redirect_uri: asana_oauth_callback_url,
        code: code
      }
    )

    JSON.parse(response.body).symbolize_keys
  rescue => e
    Rails.logger.error "Token exchange error: #{e.message}"
    {}
  end

  def fetch_default_workspace(access_token)
    response = HTTParty.get('https://app.asana.com/api/1.0/workspaces',
      headers: {
        'Authorization' => "Bearer #{access_token}"
      }
    )

    workspaces = JSON.parse(response.body).dig('data')
    workspaces&.first
  rescue => e
    Rails.logger.error "Workspace fetch error: #{e.message}"
    nil
  end
end