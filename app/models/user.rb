# app/models/user.rb
class User < ApplicationRecord
  has_secure_password validations: false

  # Associations
  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  has_many :time_entries, dependent: :destroy
  has_many :owned_organizations, -> { where(memberships: { role: 'owner' }) },
           through: :memberships, source: :organization
  belongs_to :current_organization, class_name: 'Organization', optional: true
  has_many :sent_invitations, class_name: 'Invitation', foreign_key: 'invited_by_id'

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :password, presence: true, length: { minimum: 6 }, if: -> { google_uid.blank? && password_digest.blank? }
  validate :only_one_personal_organization

  # Enums
  enum :role, { user: 0, admin: 1, super_admin: 2 }

  # Callbacks
  before_save :downcase_email
  after_create :ensure_current_organization

  # Scopes
  scope :active, -> { where(last_sign_in_at: 30.days.ago..) }

  # Instance methods
  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    "#{first_name[0]}#{last_name[0]}".upcase
  end

  def switch_organization!(organization)
    return false unless can_access_organization?(organization)
    update!(current_organization: organization)
    true
  end

  def needs_onboarding?
    organizations.empty?
  end

  def can_access_organization?(organization)
    organizations.include?(organization)
  end

  def role_in(organization)
    memberships.find_by(organization: organization)&.role
  end

  def owner_of?(organization)
    role_in(organization) == 'owner'
  end

  def admin_of?(organization)
    role_in(organization).in?(%w[owner admin])
  end

  def member_of?(organization)
    organizations.include?(organization)
  end

  def personal_organization
    organizations.personal.first
  end

  def business_organizations
    organizations.business
  end

  def has_only_personal_organization?
    organizations.count == 1 && organizations.personal.exists?
  end

  # OAuth methods
  def self.from_omniauth(auth)
    user = where(email: auth.info.email).first_or_initialize do |u|
      u.google_uid = auth.uid
      u.first_name = auth.info.first_name || auth.info.name.split.first
      u.last_name = auth.info.last_name || auth.info.name.split.last
      u.avatar_url = auth.info.image
      u.password = SecureRandom.hex(16) if u.new_record?
    end

    # Update OAuth info if user exists
    if user.persisted?
      user.update!(
        google_uid: auth.uid,
        avatar_url: auth.info.image,
        last_sign_in_at: Time.current
      )
    else
      user.save!
    end

    user
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end

  def ensure_current_organization
    if organizations.any? && current_organization.nil?
      update_column(:current_organization_id, organizations.first.id)
    end
  end

  def only_one_personal_organization
    personal_org_count = organizations.where(personal: true).count
    if personal_org_count > 1
      errors.add(:base, "User can only have one personal organization")
    end
  end
end
