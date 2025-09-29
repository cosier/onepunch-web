class TimeEntry < ApplicationRecord
  belongs_to :user
  belongs_to :project

  validates :started_at, presence: true

  scope :running, -> { where(ended_at: nil) }
  scope :today, -> { where(started_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_week, -> { where(started_at: Date.current.beginning_of_week..Date.current.end_of_week) }
  scope :recent, -> { order(started_at: :desc) }
  scope :billable, -> { where(billable: true) }
  scope :unbilled, -> { billable.where(billed: false) }

  before_save :calculate_duration

  # Turbo broadcasting disabled for now
  # after_create_commit -> { broadcast_prepend_to "time_entries" }
  # after_update_commit -> { broadcast_replace_to "time_entries" }
  # after_destroy_commit -> { broadcast_remove_to "time_entries" }

  def stop!
    self.ended_at = Time.current
    save!
  end

  def running?
    ended_at.nil?
  end

  def formatted_duration
    return "Running..." if running?

    hours = duration / 3600
    minutes = (duration % 3600) / 60
    seconds = duration % 60

    format("%02d:%02d:%02d", hours, minutes, seconds)
  end

  private

  def calculate_duration
    if started_at.present? && ended_at.present?
      self.duration = (ended_at - started_at).to_i
    end
  end

  def turbo_broadcasts_enabled?
    !Rails.env.test? && defined?(ActionController::Base) && ActionController::Base.respond_to?(:renderer)
  end
end