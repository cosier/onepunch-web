class OrganizationSwitcherController < ApplicationController
  before_action :authenticate_user!

  def switch
    organization = current_user.organizations.find(params[:id])

    if current_user.switch_organization!(organization)
      redirect_to dashboard_path, notice: "Switched to #{organization.name}"
    else
      redirect_back fallback_location: dashboard_path,
                    alert: "Could not switch organization"
    end
  end
end
