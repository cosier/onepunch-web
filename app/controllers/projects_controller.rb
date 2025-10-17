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

    # Calendar data for monthly view
    @calendar_month = params[:month] ? Date.parse(params[:month]) : current_date
    @calendar_start = @calendar_month.beginning_of_month.beginning_of_week
    @calendar_end = @calendar_month.end_of_month.end_of_week

    # Get all days with time entries in the calendar range
    @days_with_entries = @project.time_entries
      .where(started_at: @calendar_start..@calendar_end)
      .group("DATE(started_at)")
      .sum(:duration)
      .transform_keys { |k| Date.parse(k.to_s) }
      .transform_values { |v| (v || 0) / 3600.0 }

    # Daily breakdown for the current week with summaries
    @daily_breakdown = (0..6).map do |days_ago|
      day = current_date.beginning_of_week + days_ago.days
      entries = @project.time_entries.where(started_at: day.beginning_of_day..day.end_of_day)

      # Generate or fetch summary for the day
      summary_text = ""
      if entries.any?
        slug = Summary.generate_slug(day, @project.id, entries.count)
        descriptions = entries.pluck(:description).reject(&:blank?)

        if descriptions.any?
          summary = Summary.find_or_create_for(slug, descriptions)
          summary_text = summary.ready? ? summary.summarized_text : "Generating summary..."
        else
          summary_text = "#{entries.count} time #{entries.count == 1 ? 'entry' : 'entries'} recorded"
        end
      end

      {
        date: day,
        day_name: day.strftime('%A'),
        day_short: day.strftime('%a'),
        hours: (entries.sum(:duration) || 0) / 3600.0,
        billable_hours: (entries.billable.sum(:duration) || 0) / 3600.0,
        entries: entries.count,
        summary: summary_text,
        has_entries: entries.any?
      }
    end
  end

  def new
    # Determine which organization to use (current or most recent)
    org = current_organization || current_user.organizations.order(created_at: :desc).first

    @project = org&.projects&.build || Project.new
    @clients = org&.clients || Client.none
    @organizations = current_user.organizations.order(created_at: :desc)
  end

  def create
    # If organization_id provided in params, use it; otherwise fallback to current or most recent
    org_id = project_params[:organization_id].presence ||
             current_organization&.id ||
             current_user.organizations.order(created_at: :desc).first&.id

    org = current_user.organizations.find(org_id) if org_id
    @project = org&.projects&.build(project_params.except(:organization_id)) || Project.new(project_params.except(:organization_id))

    if @project.save
      redirect_to projects_path, notice: "Project was successfully created."
    else
      @clients = org&.clients || Client.none
      @organizations = current_user.organizations.order(created_at: :desc)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @clients = current_organization&.clients || Client.none
    @organizations = current_user.organizations.order(created_at: :desc)
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
    # Allow access to projects across all user's organizations
    @project = Project.joins(:organization).where(organizations: { id: current_user.organization_ids }).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to projects_path, alert: "Project not found or you don't have access to it."
  end

  def project_params
    params.require(:project).permit(:name, :description, :hourly_rate, :color, :client_id, :status, :organization_id)
  end
end