class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [:show, :edit, :update, :destroy, :archive]

  def index
    @projects = current_organization&.projects&.active || Project.none
    @archived_projects = current_organization&.projects&.archived || Project.none
  end

  def show
    @time_entries = @project.time_entries.recent.includes(:user).limit(20)
    @total_time = @project.time_entries.sum(:duration) || 0
    @billable_time = @project.time_entries.billable.sum(:duration) || 0
  end

  def new
    @project = current_organization&.projects&.build || Project.new
    @clients = current_organization&.clients || Client.none
  end

  def create
    @project = current_organization&.projects&.build(project_params) || Project.new

    if @project.save
      redirect_to projects_path, notice: "Project was successfully created."
    else
      @clients = current_organization&.clients || Client.none
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @clients = current_organization&.clients || Client.none
  end

  def update
    if @project.update(project_params)
      redirect_to project_path(@project), notice: "Project was successfully updated."
    else
      @clients = current_organization&.clients || Client.none
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_path, notice: "Project was successfully deleted."
  end

  def archive
    @project.update(archived: !@project.archived?)
    status = @project.archived? ? "archived" : "unarchived"
    redirect_to projects_path, notice: "Project was successfully #{status}."
  end

  private

  def set_project
    @project = current_organization&.projects&.find(params[:id]) || Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :hourly_rate, :color, :client_id, :status)
  end
end