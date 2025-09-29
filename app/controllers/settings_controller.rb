class SettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization

  def index
    @organizations = current_user.organizations
    @settings = @organization.organization_setting || @organization.build_organization_setting
  end

  def organization
    @organizations = current_user.organizations
    @settings = @organization.organization_setting || @organization.build_organization_setting
  end

  def profile
  end

  def billing
  end

  private

  def set_organization
    @organization = current_user.current_organization
    redirect_to onboarding_path, alert: "Please complete onboarding first" if @organization.nil?
  end
end
