class AsanaTasksController < ApplicationController
  before_action :authenticate_user!

  # JSON API for fetching Asana tasks with filtering
  # Used by time entry form for task selection
  def index
    unless current_user.asana_connected?
      render json: { error: "Asana not connected" }, status: :unauthorized
      return
    end

    # Build query
    tasks = AsanaTask.unassigned.incomplete

    # Apply filters
    tasks = tasks.by_workspace(params[:workspace]) if params[:workspace].present?
    tasks = tasks.by_project_gid(params[:project_gid]) if params[:project_gid].present?
    tasks = tasks.search(params[:search]) if params[:search].present?

    # Limit results
    tasks = tasks.limit(params[:limit] || 100)

    # Group by workspace and project for nested optgroups
    grouped_tasks = group_tasks_for_select(tasks)

    render json: {
      success: true,
      count: tasks.count,
      grouped_tasks: grouped_tasks
    }
  rescue => e
    Rails.logger.error "AsanaTasks index error: #{e.message}"
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def group_tasks_for_select(tasks)
    grouped = {}

    tasks.each do |task|
      workspace_name = task.cached_workspace_name || "Unknown Workspace"
      project_name = task.cached_project_name || "Unknown Project"

      grouped[workspace_name] ||= {}
      grouped[workspace_name][project_name] ||= []
      grouped[workspace_name][project_name] << {
        value: task.asana_gid,
        label: task.display_name,
        completed: task.completed,
        due_date: task.due_date
      }
    end

    grouped
  end
end
