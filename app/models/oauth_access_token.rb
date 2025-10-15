# app/models/oauth_access_token.rb
class OauthAccessToken < ApplicationRecord
  belongs_to :oauth_application
  belongs_to :user

  # Validations
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  # Callbacks
  before_validation :generate_tokens, on: :create
  before_validation :set_expiration, on: :create

  # Scopes
  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :revoked, -> { where.not(revoked_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def revoke!
    update!(revoked_at: Time.current)
  end

  def active?
    revoked_at.nil? && !expired?
  end

  def expired?
    expires_at <= Time.current
  end

  def revoked?
    revoked_at.present?
  end

  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end

  def scopes_list
    (scopes || "api").split(" ")
  end

  def as_json(options = {})
    {
      access_token: token,
      token_type: "Bearer",
      expires_in: expires_in_seconds,
      refresh_token: refresh_token,
      scope: scopes || "api",
      created_at: created_at.to_i
    }
  end

  private

  def generate_tokens
    self.token ||= SecureRandom.urlsafe_base64(32)
    self.refresh_token ||= SecureRandom.urlsafe_base64(32) if refresh_token_enabled?
  end

  def set_expiration
    # Access tokens expire in 30 days
    self.expires_at ||= 30.days.from_now
  end

  def refresh_token_enabled?
    # Enable refresh tokens for all OAuth tokens
    true
  end

  def expires_in_seconds
    return 0 if expired?
    (expires_at - Time.current).to_i
  end
end
