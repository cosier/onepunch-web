module OrganizationScoped
  extend ActiveSupport::Concern

  included do
    before_action :require_organization!
    before_action :set_organization_context
    helper_method :current_organization
  end

  private

  def require_organization!
    return unless user_signed_in?

    if current_user.needs_onboarding?
      redirect_to new_onboarding_path, notice: "Please create or join an organization to continue."
    elsif current_user.current_organization.nil?
      # Auto-select first organization if user has any
      if current_user.organizations.any?
        current_user.switch_organization!(current_user.organizations.first)
      else
        redirect_to new_onboarding_path
      end
    end
  end

  def set_organization_context
    @current_organization = current_user&.current_organization
  end

  def current_organization
    @current_organization
  end

  def scope_to_organization(relation)
    relation.where(organization: current_organization)
  end

  def authorize_organization_access!
    unless current_user.can_access_organization?(current_organization)
      redirect_to dashboard_path, alert: "You don't have access to this organization."
    end
  end

  def authorize_organization_admin!
    unless current_user.admin_of?(current_organization)
      redirect_to dashboard_path, alert: "You need admin privileges for this action."
    end
  end

  def authorize_organization_owner!
    unless current_user.owner_of?(current_organization)
      redirect_to dashboard_path, alert: "Only organization owners can perform this action."
    end
  end
end