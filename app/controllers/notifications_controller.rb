# app/controllers/notifications_controller.rb
class NotificationsController < ApplicationController
  before_action :authenticate_user!

  # POST /notifications/dismiss
  def dismiss
    notification_type = params[:notification_type]

    if notification_type.blank?
      render json: { error: "notification_type is required" }, status: :bad_request
      return
    end

    current_user.dismiss_notification!(notification_type)

    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path, notice: "Notification dismissed") }
      format.turbo_stream
      format.json { render json: { success: true } }
    end
  end
end
