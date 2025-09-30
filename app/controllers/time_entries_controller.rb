class TimeEntriesController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :authenticate_user!
  before_action :set_time_entry, only: [:show, :edit, :update, :destroy, :stop, :resume]

  def index
    # Get selected organizations (default to current if none selected)
    selected_org_ids = if params[:organization_ids].present?
      params[:organization_ids].reject(&:blank?)
    else
      [current_organization&.id].compact
    end

    # Validate user has access to these organizations
    @selected_organizations = current_user.organizations.where(id: selected_org_ids)
    valid_org_ids = @selected_organizations.pluck(:id)

    # Get all projects from valid organizations grouped by organization
    @projects_by_org = valid_org_ids.each_with_object({}) do |org_id, hash|
      org = current_user.organizations.find(org_id)
      hash[org_id] = {
        name: org.display_name,
        projects: org.projects.active.map { |p| { id: p.id, name: p.name, color: p.color } }
      }
    end

    # Get all project IDs for filtering time entries
    all_project_ids = @projects_by_org.values.flat_map { |org| org[:projects].map { |p| p[:id] } }

    # Filter time entries
    @time_entries = current_user.time_entries
      .where(project_id: all_project_ids)
      .recent
      .includes(:project)

    # Apply additional filters
    @time_entries = @time_entries.where(project_id: params[:project_id]) if params[:project_id].present?
    @time_entries = @time_entries.where("DATE(started_at) = ?", params[:date]) if params[:date].present?

    # TODO: Add pagination gem (kaminari or pagy) and uncomment:
    # @time_entries = @time_entries.page(params[:page]).per(25)
    @time_entries = @time_entries.limit(100) # Temporary limit without pagination

    # All organizations for filter dropdown
    @all_organizations = current_user.organizations
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
        format.turbo_stream {
          # Update timer button for the stopped project
          render turbo_stream: [
            turbo_stream.replace("timer_status", partial: "dashboard/timer_status", locals: { current_user: current_user }),
            turbo_stream.replace(dom_id(@time_entry), partial: "time_entries/entry_card", locals: { entry: @time_entry }),
            turbo_stream.replace("timer_button_#{@time_entry.project_id}",
              partial: "shared/timer_button",
              locals: { project: @time_entry.project })
          ]
        }
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
    # Ensure the time entry belongs to a project in the current organization
    org_project_ids = current_organization&.projects&.pluck(:id) || []
    @time_entry = current_user.time_entries.where(project_id: org_project_ids).find(params[:id])
  end

  def time_entry_params
    params.require(:time_entry).permit(:project_id, :description, :started_at, :ended_at, :billable)
  end
end