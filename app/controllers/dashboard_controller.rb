class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @current_timer = current_user.time_entries.running.first
    @today_duration = current_user.time_entries.today.sum(:duration) || 0
    @week_duration = current_user.time_entries.this_week.sum(:duration) || 0
    @recent_entries = current_user.time_entries.recent.includes(:project).limit(10)
    @projects = current_organization&.projects&.active || []
  end
end