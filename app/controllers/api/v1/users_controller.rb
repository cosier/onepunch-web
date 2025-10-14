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
      current_organization: organization_json(current_organization),
      organizations: current_api_user.organizations.map { |org| organization_json(org) }
    })
  end

  # POST /api/v1/users/regenerate_token
  def regenerate_token
    current_api_user.regenerate_api_token!
    render_success({
      api_token: current_api_user.api_token,
      message: "API token has been regenerated. Please update your applications."
    })
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
