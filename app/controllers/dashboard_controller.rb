class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # Scope time entries to current organization through projects
    org_project_ids = current_organization&.projects&.pluck(:id) || []
    scoped_entries = current_user.time_entries.where(project_id: org_project_ids)

    @current_timer = scoped_entries.running.first
    @today_duration = scoped_entries.today.sum(:duration) || 0
    @week_duration = scoped_entries.this_week.sum(:duration) || 0
    @recent_entries = scoped_entries.recent.includes(:project).limit(10)
    @projects = current_organization&.projects&.active || []

    # Enhanced analytics data
    current_date = Date.current

    # Daily breakdown for current week
    @daily_breakdown = (0..6).map do |days_ago|
      day = current_date.beginning_of_week + days_ago.days
      entries = scoped_entries.where(started_at: day.beginning_of_day..day.end_of_day)
      {
        date: day,
        day_name: day.strftime('%A'),
        day_short: day.strftime('%a'),
        hours: (entries.sum(:duration) || 0) / 3600.0,
        billable_hours: (entries.billable.sum(:duration) || 0) / 3600.0,
        entries: entries.count,
        projects: entries.includes(:project).pluck(:project_id).uniq.count
      }
    end

    # Weekly breakdown for last 8 weeks
    @weekly_breakdown = (0..7).map do |weeks_ago|
      week_start = current_date.beginning_of_week - weeks_ago.weeks
      week_end = week_start.end_of_week
      entries = scoped_entries.where(started_at: week_start..week_end)
      {
        week: week_start.strftime('%b %d'),
        hours: (entries.sum(:duration) || 0) / 3600.0,
        billable_hours: (entries.billable.sum(:duration) || 0) / 3600.0
      }
    end.reverse

    # Monthly breakdown for current year
    @monthly_breakdown = (1..12).map do |month|
      start_date = Date.new(current_date.year, month, 1)
      end_date = start_date.end_of_month
      entries = scoped_entries.where(started_at: start_date..end_date)
      {
        month: start_date.strftime('%b'),
        hours: (entries.sum(:duration) || 0) / 3600.0,
        billable_hours: (entries.billable.sum(:duration) || 0) / 3600.0
      }
    end

    # Calendar data for monthly view
    @calendar_month = params[:month] ? Date.parse(params[:month]) : current_date
    @calendar_start = @calendar_month.beginning_of_month.beginning_of_week
    @calendar_end = @calendar_month.end_of_month.end_of_week

    # Get all days with time entries in the calendar range
    @days_with_entries = scoped_entries
      .where(started_at: @calendar_start..@calendar_end)
      .group("DATE(started_at)")
      .sum(:duration)
      .transform_keys { |k| Date.parse(k.to_s) }
      .transform_values { |v| (v || 0) / 3600.0 }

    # Project breakdown for today
    @today_projects = scoped_entries
      .today
      .includes(:project)
      .group(:project)
      .sum(:duration)
      .transform_values { |v| (v || 0) / 3600.0 }
      .sort_by { |_, hours| -hours }

    # Current month stats
    @current_month_start = current_date.beginning_of_month
    @current_month_entries = scoped_entries.where(started_at: @current_month_start..current_date.end_of_month)
    @current_month_hours = (@current_month_entries.sum(:duration) || 0) / 3600.0
    @current_month_billable = (@current_month_entries.billable.sum(:duration) || 0) / 3600.0
  end
end