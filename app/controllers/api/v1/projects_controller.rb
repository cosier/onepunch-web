# app/controllers/api/v1/projects_controller.rb
class Api::V1::ProjectsController < Api::BaseController
  before_action :set_organization
  before_action :set_project, only: [:show, :update]

  # GET /api/v1/projects
  def index
    @projects = @organization.projects.includes(:client)

    # Optional filters
    @projects = @projects.active unless params[:include_archived] == "true"
    @projects = @projects.where(status: params[:status]) if params[:status].present?

    render_success(@projects.map { |project| project_json(project) })
  end

  # GET /api/v1/projects/:id
  def show
    render_success(project_json(@project, include_stats: true))
  end

  # POST /api/v1/projects
  def create
    @project = @organization.projects.build(project_params)

    if @project.save
      render_success(project_json(@project), status: :created)
    else
      render json: {
        error: "Validation failed",
        details: @project.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/projects/:id
  def update
    if @project.update(project_params)
      render_success(project_json(@project))
    else
      render json: {
        error: "Validation failed",
        details: @project.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_organization
    @organization = organization_from_request
    unless @organization
      render_error("No organization found", status: :not_found)
    end
  end

  def set_project
    @project = @organization.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(
      :name,
      :description,
      :client_id,
      :hourly_rate,
      :status,
      :color
    )
  end

  def project_json(project, include_stats: false)
    result = {
      id: project.id,
      name: project.name,
      description: project.description,
      client_id: project.client_id,
      client_name: project.client&.name,
      hourly_rate: project.hourly_rate,
      status: project.status,
      color: project.color,
      archived: project.archived,
      created_at: project.created_at,
      updated_at: project.updated_at
    }

    if include_stats
      result[:stats] = {
        total_hours: project.total_hours.round(2),
        unbilled_hours: project.unbilled_hours.round(2),
        total_revenue: project.total_revenue&.round(2)
      }
    end

    result
  end
end
