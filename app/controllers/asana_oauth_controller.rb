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
      # Create or update credential
      credential = current_user.asana_credential || current_user.build_asana_credential

      # Fetch Asana user info to get the user GID
      api_service = AsanaApiService.new(credential)
      credential.access_token = token_response[:access_token]
      user_info = api_service.test_connection

      # Check if this Asana account is already connected to another user
      if user_info[:success] && user_info[:asana_gid]
        existing_credential = AsanaCredential.find_by(asana_user_gid: user_info[:asana_gid])
        if existing_credential && existing_credential.user_id != current_user.id
          redirect_to settings_integrations_asana_path,
            alert: "This Asana account (#{user_info[:email]}) is already connected to another OnePunch account."
          return
        end
      end

      credential.update!(
        access_token: token_response[:access_token],
        refresh_token: token_response[:refresh_token],
        expires_at: Time.current + token_response[:expires_in].to_i.seconds,
        asana_user_gid: user_info[:asana_gid]
      )

      # Sync workspaces in background
      AsanaSyncJob.perform_later(current_user.id)

      redirect_to settings_integrations_asana_path, notice: "Asana connected successfully! Syncing your workspaces..."
    else
      redirect_to settings_integrations_asana_path, alert: "Failed to connect Asana. Please try again."
    end
  rescue => e
    Rails.logger.error "Asana OAuth error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to settings_integrations_asana_path, alert: "An error occurred while connecting Asana: #{e.message}"
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

end