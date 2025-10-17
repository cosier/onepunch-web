# app/models/api_token.rb
class ApiToken < ApplicationRecord
  belongs_to :user

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :token, presence: true, uniqueness: true

  # Scopes
  scope :active, -> { where(revoked_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :revoked, -> { where.not(revoked_at: nil) }
  scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ?", Time.current) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_validation :generate_token, on: :create

  # Instance methods
  def revoke!
    update!(revoked_at: Time.current)
  end

  def active?
    revoked_at.nil? && !expired?
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def revoked?
    revoked_at.present?
  end

  def mask_token
    return "••••••••" if token.blank?

    # Show first 8 chars and last 4 chars
    if token.length > 12
      "#{token[0..7]}...#{token[-4..]}"
    else
      "#{token[0..3]}...#{token[-2..]}"
    end
  end

  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end

  def status
    return "revoked" if revoked?
    return "expired" if expired?
    "active"
  end

  def status_color
    case status
    when "active" then "green"
    when "expired" then "yellow"
    when "revoked" then "red"
    else "gray"
    end
  end

  private

  def generate_token
    self.token ||= loop do
      token = SecureRandom.urlsafe_base64(32)
      break token unless ApiToken.exists?(token: token)
    end
  end
end
