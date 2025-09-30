# Service class for centralized Asana API interactions
# Handles authentication, rate limiting, and error handling
class AsanaApiService
  BASE_URL = "https://app.asana.com/api/1.0"

  class ApiError < StandardError; end
  class RateLimitError < ApiError; end
  class AuthenticationError < ApiError; end

  def initialize(credential)
    @credential = credential
    @access_token = credential.access_token
  end

  # Generic GET request to Asana API
  def get(path, params = {})
    url = "#{BASE_URL}/#{path.delete_prefix('/')}"

    response = HTTParty.get(url,
      headers: headers,
      query: params,
      timeout: 30
    )

    handle_response(response)
  end

  # Fetch all workspaces accessible to the user
  def fetch_workspaces
    response = get('workspaces', {})
    response['data'] || []
  end

  # Fetch projects for a specific workspace
  def fetch_projects(workspace_gid)
    response = get('projects', {
      workspace: workspace_gid,
      archived: false
    })
    response['data'] || []
  end

  # Fetch tasks for a specific project
  def fetch_tasks(project_gid, opts = {})
    params = {
      project: project_gid,
      opt_fields: 'name,completed,due_on,assignee.gid',
      limit: opts[:limit] || 100
    }

    params[:completed_since] = opts[:completed_since] if opts[:completed_since]

    response = get('tasks', params)
    response['data'] || []
  end

  # Refresh the access token using refresh token
  def refresh_access_token!
    return false unless @credential.refresh_token.present?

    response = HTTParty.post("https://app.asana.com/-/oauth_token",
      body: {
        grant_type: 'refresh_token',
        client_id: client_id,
        client_secret: client_secret,
        refresh_token: @credential.refresh_token
      }
    )

    if response.code == 200
      data = JSON.parse(response.body)
      @credential.update!(
        access_token: data['access_token'],
        refresh_token: data['refresh_token'],
        expires_at: Time.current + data['expires_in'].to_i.seconds
      )
      @access_token = data['access_token']
      true
    else
      false
    end
  rescue => e
    Rails.logger.error "Token refresh failed: #{e.message}"
    false
  end

  # Test connection to Asana API
  def test_connection
    response = get('users/me')
    {
      success: true,
      asana_gid: response.dig('data', 'gid'),
      user: response.dig('data', 'name'),
      email: response.dig('data', 'email')
    }
  rescue => e
    {
      success: false,
      error: e.message
    }
  end

  private

  def headers
    {
      'Authorization' => "Bearer #{@access_token}",
      'Accept' => 'application/json'
    }
  end

  def handle_response(response)
    case response.code
    when 200..299
      JSON.parse(response.body)
    when 401
      # Try to refresh token once
      if refresh_access_token!
        # Retry request with new token
        return get(response.request.path.to_s, response.request.options[:query] || {})
      else
        raise AuthenticationError, "Authentication failed"
      end
    when 429
      # Rate limited
      retry_after = response.headers['Retry-After']&.to_i || 60
      raise RateLimitError, "Rate limited. Retry after #{retry_after} seconds"
    else
      error_message = JSON.parse(response.body).dig('errors', 0, 'message') rescue response.body
      raise ApiError, "API error (#{response.code}): #{error_message}"
    end
  rescue JSON::ParserError => e
    raise ApiError, "Invalid JSON response: #{e.message}"
  end

  def client_id
    ENV['ASANA_CLIENT_ID'] || Rails.application.credentials.dig(:asana, :client_id)
  end

  def client_secret
    ENV['ASANA_CLIENT_SECRET'] || Rails.application.credentials.dig(:asana, :client_secret)
  end
end