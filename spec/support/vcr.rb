require 'vcr'

VCR.configure do |config|
  # Store cassettes in spec/fixtures/vcr_cassettes
  config.cassette_library_dir = Rails.root.join('spec', 'fixtures', 'vcr_cassettes')

  # Use webmock to intercept HTTP requests
  config.hook_into :webmock

  # Filter sensitive data from cassettes
  config.filter_sensitive_data('<ASANA_ACCESS_TOKEN>') do |interaction|
    # Extract Bearer token from Authorization header
    auth_header = interaction.request.headers['Authorization']&.first
    if auth_header && auth_header.start_with?('Bearer ')
      auth_header.sub('Bearer ', '')
    end
  end

  config.filter_sensitive_data('<ASANA_CLIENT_ID>') do
    ENV['ASANA_CLIENT_ID'] || Rails.application.credentials.dig(:asana, :client_id)
  end

  config.filter_sensitive_data('<ASANA_CLIENT_SECRET>') do
    ENV['ASANA_CLIENT_SECRET'] || Rails.application.credentials.dig(:asana, :client_secret)
  end

  # Configure RSpec metadata
  config.configure_rspec_metadata!

  # Allow requests to localhost (for development)
  config.ignore_localhost = true

  # Automatically record new episodes
  config.default_cassette_options = {
    record: :once, # Record new interactions once, then replay
    match_requests_on: [:method, :uri, :body]
  }
end