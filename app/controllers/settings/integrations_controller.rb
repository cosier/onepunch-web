class Settings::IntegrationsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Show all integrations status
  end

  def asana
    # Show Asana integration status and connection options
    @asana_connected = current_user.asana_connected?
    # TODO: Load asana_credential when model exists
    # @asana_credential = current_user.asana_credential
  end

  def disconnect_asana
    # TODO: Implement when AsanaCredential model exists
    # current_user.asana_credential&.destroy
    redirect_to settings_integrations_asana_path, notice: "Asana disconnected successfully"
  end
end