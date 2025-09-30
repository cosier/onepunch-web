class Settings::IntegrationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_asana_data, only: [:asana]

  def index
    # Show all integrations status
  end

  def asana
    # @asana_connected, @asana_credential, @workspaces set in before_action
  end

  def sync_asana
    unless current_user.asana_connected?
      redirect_to settings_integrations_asana_path, alert: "Asana is not connected"
      return
    end

    AsanaSyncJob.perform_later(current_user.id)
    redirect_to settings_integrations_asana_path, notice: "Syncing Asana data in background..."
  end

  def disconnect_asana
    current_user.asana_credential&.destroy
    redirect_to settings_integrations_asana_path, notice: "Asana disconnected successfully"
  end

  # Development-only endpoints for testing API connection
  if Rails.env.development?
    def test_connection
      unless current_user.asana_connected?
        render json: { success: false, error: "Not connected to Asana" }, status: :unauthorized
        return
      end

      api_service = AsanaApiService.new(current_user.asana_credential)
      result = api_service.test_connection

      render json: result
    end

    def list_workspaces
      unless current_user.asana_connected?
        render json: { success: false, error: "Not connected to Asana" }, status: :unauthorized
        return
      end

      api_service = AsanaApiService.new(current_user.asana_credential)
      workspaces = api_service.fetch_workspaces

      render json: {
        success: true,
        count: workspaces.count,
        workspaces: workspaces
      }
    rescue => e
      render json: { success: false, error: e.message }, status: :internal_server_error
    end
  end

  private

  def set_asana_data
    @asana_connected = current_user.asana_connected?
    @asana_credential = current_user.asana_credential
    @workspaces = current_user.asana_workspaces.order(:name) if @asana_connected
  end
end