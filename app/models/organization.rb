# app/models/organization.rb
class Organization < ApplicationRecord
  # Associations
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :projects, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_one :organization_setting, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  # Callbacks
  before_validation :generate_slug
  after_create :set_default_settings
  after_create :create_organization_setting

  # Scopes
  scope :onboarded, -> { where.not(onboarded_at: nil) }
  scope :in_trial, -> { where(subscription_status: 'trial') }
  scope :active, -> { where(subscription_status: %w[trial active]) }
  scope :personal, -> { where(personal: true) }
  scope :business, -> { where(personal: false) }

  # Instance methods
  def display_name
    personal? ? "Personal Org." : name
  end
  def owner
    memberships.find_by(role: "owner")&.user
  end

  def onboarded?
    onboarded_at.present?
  end

  def complete_onboarding!
    update!(onboarded_at: Time.current)
  end

  def add_member(user, role: 'member', invited_by: nil)
    memberships.create!(
      user: user,
      role: role,
      joined_at: Time.current
    )
  end

  def member_count
    memberships.count
  end

  def active_projects_count
    projects.where(archived: false).count
  end

  def trial?
    subscription_status == 'trial'
  end

  def trial_expired?
    trial? && trial_ends_at.present? && trial_ends_at < Time.current
  end

  private

  def generate_slug
    self.slug = name.parameterize if name.present? && slug.blank?
  end

  def set_default_settings
    self.subscription_status ||= 'trial'
    self.trial_ends_at ||= 14.days.from_now
  end
end
