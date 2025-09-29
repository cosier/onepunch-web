class TimeEntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_time_entry, only: [:show, :edit, :update, :destroy, :stop, :resume]

  def index
    @time_entries = current_user.time_entries.recent.includes(:project)
    @time_entries = @time_entries.where("DATE(started_at) = ?", params[:date]) if params[:date].present?
    @time_entries = @time_entries.where(project_id: params[:project_id]) if params[:project_id].present?
    # TODO: Add pagination gem (kaminari or pagy) and uncomment:
    # @time_entries = @time_entries.page(params[:page]).per(25)
    @time_entries = @time_entries.limit(100) # Temporary limit without pagination
    @projects = current_organization&.projects&.active || []
  end

  def show
  end

  def new
    @time_entry = current_user.time_entries.build
    @projects = current_organization&.projects&.active || []
  end

  def create
    @time_entry = current_user.time_entries.build(time_entry_params)
    @time_entry.ended_at = Time.current if @time_entry.started_at.present?

    if @time_entry.save
      redirect_to time_entries_path, notice: "Time entry was successfully created."
    else
      @projects = current_organization&.projects&.active || []
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @projects = current_organization&.projects&.active || []
  end

  def update
    if @time_entry.update(time_entry_params)
      redirect_to time_entries_path, notice: "Time entry was successfully updated."
    else
      @projects = current_organization&.projects&.active || []
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @time_entry.destroy

    respond_to do |format|
      format.html { redirect_to time_entries_path, notice: "Time entry was successfully deleted." }
      format.turbo_stream
    end
  end

  def stop
    if @time_entry.running?
      @time_entry.stop!

      respond_to do |format|
        format.html { redirect_back(fallback_location: time_entries_path, notice: "Timer stopped successfully.") }
        format.turbo_stream
      end
    else
      redirect_back(fallback_location: time_entries_path, alert: "Timer is not running.")
    end
  end

  def resume
    # Stop any currently running timers
    current_user.time_entries.running.each(&:stop!)

    # Create a new entry with the same attributes
    new_entry = current_user.time_entries.create!(
      project_id: @time_entry.project_id,
      description: @time_entry.description,
      billable: @time_entry.billable,
      started_at: Time.current
    )

    respond_to do |format|
      format.html { redirect_to dashboard_path, notice: "Timer resumed successfully." }
      format.turbo_stream {
        @time_entry = new_entry
        render :resume
      }
    end
  rescue => e
    redirect_back(fallback_location: time_entries_path, alert: "Failed to resume timer: #{e.message}")
  end

  private

  def set_time_entry
    @time_entry = current_user.time_entries.find(params[:id])
  end

  def time_entry_params
    params.require(:time_entry).permit(:project_id, :description, :started_at, :ended_at, :billable)
  end
end