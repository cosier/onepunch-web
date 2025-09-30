class Settings::IntegrationsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Show all integrations status
  end

  def asana
    @asana_connected = current_user.asana_connected?
    @asana_credential = current_user.asana_credential
  end

  def disconnect_asana
    current_user.asana_credential&.destroy
    redirect_to settings_integrations_asana_path, notice: "Asana disconnected successfully"
  end
end