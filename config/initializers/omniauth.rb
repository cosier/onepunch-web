Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    ENV['GOOGLE_CLIENT_ID'] || Rails.application.credentials.dig(:google, :client_id),
    ENV['GOOGLE_CLIENT_SECRET'] || Rails.application.credentials.dig(:google, :client_secret),
    {
      scope: 'email,profile',
      prompt: 'select_account',
      image_aspect_ratio: 'square',
      image_size: 200,
      name: 'google',
      access_type: 'offline',
      skip_jwt: true,
      provider_ignores_state: true  # Disable CSRF check for OAuth
    }
end

OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true

# Handle OAuth failures gracefully
OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}