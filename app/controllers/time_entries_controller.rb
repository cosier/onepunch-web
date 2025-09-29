class TimeEntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_time_entry, only: [:show, :edit, :update, :destroy]

  def index
    @time_entries = current_user.time_entries.recent.includes(:project)
    @time_entries = @time_entries.where("DATE(started_at) = ?", params[:date]) if params[:date].present?
    @time_entries = @time_entries.where(project_id: params[:project_id]) if params[:project_id].present?
    @time_entries = @time_entries.page(params[:page]).per(25)
    @projects = current_organization&.projects&.active || []
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
    redirect_to time_entries_path, notice: "Time entry was successfully deleted."
  end

  private

  def set_time_entry
    @time_entry = current_user.time_entries.find(params[:id])
  end

  def time_entry_params
    params.require(:time_entry).permit(:project_id, :description, :started_at, :ended_at, :billable)
  end
end