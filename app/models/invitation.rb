class Invitation < ApplicationRecord
  belongs_to :organization
  belongs_to :invited_by, class_name: 'User', optional: true

  # Validations
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :role, inclusion: { in: %w[owner admin member] }
  validate :email_not_already_member, on: :create

  # Callbacks
  before_validation :generate_token, on: :create
  before_create :set_expiration

  # Scopes
  scope :pending, -> { where(accepted_at: nil) }
  scope :accepted, -> { where.not(accepted_at: nil) }
  scope :expired, -> { where('expires_at < ?', Time.current) }
  scope :valid, -> { pending.where('expires_at > ?', Time.current) }

  # Instance methods
  def accepted?
    accepted_at.present?
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def still_valid?
    !accepted? && !expired?
  end

  def accept!(user)
    return false unless still_valid?

    transaction do
      # Create membership
      organization.add_member(user, role: role, invited_by: invited_by)

      # Mark invitation as accepted
      update!(accepted_at: Time.current)

      # Set as user's current organization if they don't have one
      if user.current_organization.nil?
        user.update!(current_organization: organization)
      end
    end

    true
  end

  def invitation_url
    Rails.application.routes.url_helpers.accept_invitation_url(token: token, host: ENV['APP_HOST'])
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at ||= 7.days.from_now
  end

  def email_not_already_member
    if organization && organization.users.exists?(email: email)
      errors.add(:email, 'is already a member of this organization')
    end
  end
end
