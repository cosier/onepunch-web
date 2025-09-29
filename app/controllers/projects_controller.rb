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

    # Analytics data
    current_date = Date.current

    # Monthly breakdown for current year
    @monthly_breakdown = (1..12).map do |month|
      start_date = Date.new(current_date.year, month, 1)
      end_date = start_date.end_of_month
      entries = @project.time_entries.where(started_at: start_date..end_date)
      {
        month: start_date.strftime('%b'),
        hours: (entries.sum(:duration) || 0) / 3600.0,
        billable_hours: (entries.billable.sum(:duration) || 0) / 3600.0
      }
    end

    # Weekly breakdown for last 8 weeks
    @weekly_breakdown = (0..7).map do |weeks_ago|
      week_start = current_date.beginning_of_week - weeks_ago.weeks
      week_end = week_start.end_of_week
      entries = @project.time_entries.where(started_at: week_start..week_end)
      {
        week: week_start.strftime('%b %d'),
        hours: (entries.sum(:duration) || 0) / 3600.0,
        billable_hours: (entries.billable.sum(:duration) || 0) / 3600.0
      }
    end.reverse

    # Current month stats
    @current_month_start = current_date.beginning_of_month
    @current_month_entries = @project.time_entries.where(started_at: @current_month_start..current_date.end_of_month)
    @current_month_hours = (@current_month_entries.sum(:duration) || 0) / 3600.0
    @current_month_billable = (@current_month_entries.billable.sum(:duration) || 0) / 3600.0

    # Current week stats
    @current_week_start = current_date.beginning_of_week
    @current_week_entries = @project.time_entries.where(started_at: @current_week_start..current_date.end_of_week)
    @current_week_hours = (@current_week_entries.sum(:duration) || 0) / 3600.0
    @current_week_billable = (@current_week_entries.billable.sum(:duration) || 0) / 3600.0

    # Today's stats
    @today_entries = @project.time_entries.where(started_at: current_date.beginning_of_day..current_date.end_of_day)
    @today_hours = (@today_entries.sum(:duration) || 0) / 3600.0
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