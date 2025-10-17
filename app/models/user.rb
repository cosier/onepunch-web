# app/models/user.rb
class User < ApplicationRecord
  has_secure_password validations: false

  # Concerns
  include OnboardingRequirement

  # Associations
  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  has_many :time_entries, dependent: :destroy
  has_many :api_tokens, dependent: :destroy
  has_many :owned_organizations, -> { where(memberships: { role: 'owner' }) },
           through: :memberships, source: :organization
  belongs_to :current_organization, class_name: 'Organization', optional: true
  has_many :sent_invitations, class_name: 'Invitation', foreign_key: 'invited_by_id'
  has_one :asana_credential, dependent: :destroy
  has_many :asana_workspaces, dependent: :destroy

  # Preferences (JSONB storage)
  store_accessor :preferences, :dismissed_notifications

  # Avatar associations
  has_many :avatars, dependent: :destroy
  has_one :active_avatar, -> { where(active: true) }, class_name: 'Avatar'
  has_one_attached :avatar_image do |attachable|
    attachable.variant :thumb, resize_to_limit: [100, 100]
    attachable.variant :medium, resize_to_limit: [300, 300]
    attachable.variant :large, resize_to_limit: [500, 500]
  end

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

  # Integration methods
  def asana_connected?
    asana_credential.present? && !asana_credential.expired?
  end

  # Password management methods
  def has_password_set?
    password_digest.present? && !password_auto_generated?
  end

  def oauth_only_user?
    google_uid.present? && password_auto_generated?
  end

  def password_never_set?
    password_auto_generated?
  end

  def can_login_with_email?
    password_digest.present? && !password_auto_generated?
  end

  # API token methods
  def generate_api_token!(name:, expires_at: nil)
    api_tokens.create!(name: name, expires_at: expires_at)
  end

  def active_api_tokens
    api_tokens.active.recent
  end

  # Avatar methods
  def display_avatar_url(variant: nil)
    # Priority: Active Avatar > Attached Image > OAuth URL > Gravatar
    if active_avatar&.image&.attached?
      variant ? active_avatar.image.variant(variant) : active_avatar.image
    elsif avatar_image.attached?
      variant ? avatar_image.variant(variant) : avatar_image
    elsif avatar_url.present?
      avatar_url
    else
      gravatar_url
    end
  end

  def gravatar_url(size: 200)
    email_hash = Digest::MD5.hexdigest(email.downcase.strip)
    "https://www.gravatar.com/avatar/#{email_hash}?d=mp&s=#{size}"
  end

  def has_custom_avatar?
    avatar_image.attached? || active_avatar&.image&.attached?
  end

  # Preference methods
  def dismiss_notification!(notification_type)
    dismissed = dismissed_notifications || []
    dismissed << notification_type.to_s unless dismissed.include?(notification_type.to_s)
    update!(dismissed_notifications: dismissed)
  end

  def notification_dismissed?(notification_type)
    dismissed = dismissed_notifications || []
    dismissed.include?(notification_type.to_s)
  end

  def asana_setup_dismissed?
    notification_dismissed?(:asana_setup)
  end

  def dismiss_asana_setup!
    dismiss_notification!(:asana_setup)
  end

  def reset_preferences!
    update!(preferences: {})
  end

  # OAuth methods
  def self.from_omniauth(auth)
    user = where(email: auth.info.email).first_or_initialize do |u|
      u.google_uid = auth.uid
      u.first_name = auth.info.first_name || auth.info.name.split.first
      u.last_name = auth.info.last_name || auth.info.name.split.last
      u.avatar_url = auth.info.image
      if u.new_record?
        u.password = SecureRandom.hex(16)
        u.password_auto_generated = true
      end
    end

    # Track if avatar URL changed
    avatar_url_changed = user.avatar_url != auth.info.image

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

    # Queue avatar download if URL is new or changed
    if auth.info.image.present? && (user.id_previously_changed? || avatar_url_changed)
      DownloadAvatarJob.perform_later(user)
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
