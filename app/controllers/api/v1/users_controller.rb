# app/controllers/api/v1/users_controller.rb
class Api::V1::UsersController < Api::BaseController
  # GET /api/v1/users/me
  def me
    render_success({
      id: current_api_user.id,
      email: current_api_user.email,
      first_name: current_api_user.first_name,
      last_name: current_api_user.last_name,
      full_name: current_api_user.full_name,
      current_organization: current_organization ? organization_json(current_organization) : nil,
      organizations: current_api_user.organizations.map { |org| organization_json(org) }
    })
  end

  # POST /api/v1/users/regenerate_token (deprecated - use web UI for token management)
  def regenerate_token
    render json: {
      error: "This endpoint is deprecated. Please use the web UI at /settings/account to manage API tokens.",
      url: "#{request.base_url}/settings/account"
    }, status: :gone
  end

  private

  def organization_json(org)
    {
      id: org.id,
      name: org.name,
      display_name: org.display_name,
      personal: org.personal,
      role: current_api_user.role_in(org)
    }
  end
end
