class TimerController < ApplicationController
  before_action :authenticate_user!

  def start
    # Stop any currently running timers
    current_user.time_entries.running.each(&:stop!)

    @time_entry = current_user.time_entries.create!(
      project_id: params[:project_id],
      started_at: Time.current,
      description: params[:description] || "",
      billable: true # Default to billable
    )

    broadcast_timer_update

    respond_to do |format|
      format.html { redirect_back(fallback_location: dashboard_path, notice: "Timer started successfully") }
      format.turbo_stream {
        # Update all timer buttons on the page
        all_projects = current_organization.projects.active

        streams = []
        # Update timer status
        streams << turbo_stream.replace("timer_status", partial: "dashboard/timer_status", locals: { current_user: current_user })

        # Update the timer button for the started project
        streams << turbo_stream.replace("timer_button_#{@time_entry.project_id}",
          partial: "shared/timer_button",
          locals: { project: @time_entry.project })

        # Update timer buttons for all other projects (in case one was running)
        all_projects.where.not(id: @time_entry.project_id).each do |proj|
          streams << turbo_stream.replace("timer_button_#{proj.id}",
            partial: "shared/timer_button",
            locals: { project: proj })
        end

        # Prepend new entry if list exists
        if @time_entry.project_id == params[:project_id].to_i
          streams << turbo_stream.prepend("time-entries-list", partial: "time_entries/entry_card", locals: { entry: @time_entry })
        end

        render turbo_stream: streams
      }
      format.json {
        render json: {
          id: @time_entry.id,
          started_at: @time_entry.started_at.iso8601,
          success: true
        }
      }
    end
  rescue => e
    respond_to do |format|
      format.html { redirect_back(fallback_location: dashboard_path, alert: "Failed to start timer: #{e.message}") }
      format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: e.message }) }
      format.json { render json: { success: false, error: e.message }, status: :unprocessable_entity }
    end
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