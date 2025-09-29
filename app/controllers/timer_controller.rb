class TimerController < ApplicationController
  before_action :authenticate_user!

  def start
    # Stop any currently running timers
    current_user.time_entries.running.each(&:stop!)

    @time_entry = current_user.time_entries.create!(
      project_id: params[:project_id],
      started_at: Time.current,
      description: params[:description] || ""
    )

    broadcast_timer_update
    render json: {
      id: @time_entry.id,
      started_at: @time_entry.started_at.iso8601,
      success: true
    }
  rescue => e
    render json: {
      success: false,
      error: e.message
    }, status: :unprocessable_entity
  end

  def stop
    @time_entry = current_user.time_entries.find(params[:id])
    @time_entry.stop!

    broadcast_timer_update
    render json: {
      id: @time_entry.id,
      duration: @time_entry.duration,
      success: true
    }
  rescue => e
    render json: {
      success: false,
      error: e.message
    }, status: :unprocessable_entity
  end

  private

  def broadcast_timer_update
    Turbo::StreamsChannel.broadcast_replace_to(
      "timer_#{current_user.id}",
      target: "timer_status",
      partial: "dashboard/timer_status",
      locals: { current_user: current_user }
    )
  end
end