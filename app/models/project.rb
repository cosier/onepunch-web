# app/models/project.rb
class Project < ApplicationRecord
  # Associations
  belongs_to :organization
  belongs_to :client, optional: true
  has_many :time_entries, dependent: :destroy
  has_many :invoices, dependent: :nullify
  has_one :asana_project, dependent: :destroy
  
  # Validations
  validates :name, presence: true
  
  # Enums
  enum :status, { active: 0, on_hold: 1, completed: 2, cancelled: 3 }
  
  # Scopes
  scope :active, -> { where(archived: false, status: :active) }
  scope :archived, -> { where(archived: true) }
  scope :billable, -> { where.not(hourly_rate: nil) }
  
  # Callbacks
  before_create :set_default_color
  
  # Instance methods
  def total_hours
    time_entries.sum(:duration) / 3600.0
  end
  
  def total_revenue
    return 0 unless hourly_rate
    total_hours * hourly_rate
  end
  
  def unbilled_hours
    time_entries.billable.where(billed: false).sum(:duration) / 3600.0
  end
  
  private
  
  def set_default_color
    self.color ||= "##{SecureRandom.hex(3)}"
  end
end
