# app/controllers/api/v1/time_entries_controller.rb
class Api::V1::TimeEntriesController < Api::BaseController
  before_action :set_organization
  before_action :set_time_entry, only: [:show, :update, :destroy, :stop]

  # GET /api/v1/time_entries
  def index
    org_project_ids = @organization.projects.pluck(:id)

    @time_entries = current_api_user.time_entries
      .where(project_id: org_project_ids)
      .recent
      .includes(:project)

    # Optional filters
    @time_entries = @time_entries.where(project_id: params[:project_id]) if params[:project_id].present?
    @time_entries = @time_entries.running if params[:running] == "true"
    @time_entries = @time_entries.billable if params[:billable] == "true"

    # Date range filter
    if params[:start_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current
      @time_entries = @time_entries.where(started_at: start_date.beginning_of_day..end_date.end_of_day)
    end

    # Pagination
    page = params[:page]&.to_i || 1
    per_page = [params[:per_page]&.to_i || 50, 100].min
    @time_entries = @time_entries.limit(per_page).offset((page - 1) * per_page)

    render_success(
      @time_entries.map { |entry| time_entry_json(entry) },
      meta: pagination_meta(@time_entries, page, per_page)
    )
  end

  # GET /api/v1/time_entries/:id
  def show
    render_success(time_entry_json(@time_entry))
  end

  # POST /api/v1/time_entries
  def create
    @time_entry = current_api_user.time_entries.build(time_entry_params)

    # Validate project belongs to organization
    unless @organization.projects.exists?(id: @time_entry.project_id)
      return render_error("Project not found in organization", status: :not_found)
    end

    if @time_entry.save
      render_success(time_entry_json(@time_entry), status: :created)
    else
      render json: {
        error: "Validation failed",
        details: @time_entry.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/time_entries/:id
  def update
    if @time_entry.update(time_entry_params)
      render_success(time_entry_json(@time_entry))
    else
      render json: {
        error: "Validation failed",
        details: @time_entry.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/time_entries/:id
  def destroy
    @time_entry.destroy
    head :no_content
  end

  # POST /api/v1/time_entries/:id/stop
  def stop
    if @time_entry.running?
      @time_entry.stop!
      render_success(time_entry_json(@time_entry))
    else
      render_error("Time entry is not running", status: :unprocessable_entity)
    end
  end

  private

  def set_organization
    @organization = organization_from_request
    unless @organization
      render_error("No organization found", status: :not_found)
    end
  end

  def set_time_entry
    org_project_ids = @organization.projects.pluck(:id)
    @time_entry = current_api_user.time_entries
      .where(project_id: org_project_ids)
      .find(params[:id])
  end

  def time_entry_params
    params.require(:time_entry).permit(
      :project_id,
      :description,
      :started_at,
      :ended_at,
      :billable
    )
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
      billed: entry.billed,
      running: entry.running?,
      created_at: entry.created_at,
      updated_at: entry.updated_at
    }
  end

  def pagination_meta(collection, page, per_page)
    {
      page: page,
      per_page: per_page
    }
  end
end
