# app/controllers/api/v1/timer_controller.rb
class Api::V1::TimerController < Api::BaseController
  before_action :set_organization

  # GET /api/v1/timer/current
  def current
    org_project_ids = @organization.projects.pluck(:id)
    running_entry = current_api_user.time_entries
      .where(project_id: org_project_ids)
      .running
      .first

    if running_entry
      render_success({
        running: true,
        time_entry: time_entry_json(running_entry)
      })
    else
      render_success({ running: false, time_entry: nil })
    end
  end

  # POST /api/v1/timer/start
  def start
    # Stop any currently running timers
    org_project_ids = @organization.projects.pluck(:id)
    current_api_user.time_entries
      .where(project_id: org_project_ids)
      .running
      .each(&:stop!)

    # Validate project belongs to organization
    project = @organization.projects.find_by(id: params[:project_id])
    unless project
      return render_error("Project not found in organization", status: :not_found)
    end

    # Create new time entry
    time_entry = current_api_user.time_entries.build(
      project_id: params[:project_id],
      description: params[:description],
      billable: params[:billable] || true,
      started_at: Time.current
    )

    if time_entry.save
      render_success({
        running: true,
        time_entry: time_entry_json(time_entry)
      }, status: :created)
    else
      render json: {
        error: "Failed to start timer",
        details: time_entry.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/timer/stop
  def stop
    org_project_ids = @organization.projects.pluck(:id)
    running_entry = current_api_user.time_entries
      .where(project_id: org_project_ids)
      .running
      .first

    if running_entry
      running_entry.stop!
      render_success({
        running: false,
        time_entry: time_entry_json(running_entry)
      })
    else
      render_error("No timer is currently running", status: :unprocessable_entity)
    end
  end

  private

  def set_organization
    @organization = organization_from_request
    unless @organization
      render_error("No organization found", status: :not_found)
    end
  end

  def time_entry_json(entry)
    {
      id: entry.id,
      project_id: entry.project_id,
      project_name: entry.project.name,
      description: entry.description,
      started_at: entry.started_at,
      ended_at: entry.ended_at,
      duration: entry.duration,
      formatted_duration: entry.formatted_duration,
      billable: entry.billable,
      running: entry.running?,
      created_at: entry.created_at,
      updated_at: entry.updated_at
    }
  end
end
