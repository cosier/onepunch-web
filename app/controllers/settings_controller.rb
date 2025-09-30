class SettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization

  def index
    redirect_to settings_account_path
  end

  def account
    # Account settings page (user-specific, not organization-specific)
  end

  def organization
    @organizations = current_user.organizations
    @settings = @organization.organization_setting || @organization.build_organization_setting
  end

  def billing
    # Billing settings for the current organization
  end

  private

  def set_organization
    @organization = current_user.current_organization
    redirect_to onboarding_path, alert: "Please complete onboarding first" if @organization.nil?
  end
end
