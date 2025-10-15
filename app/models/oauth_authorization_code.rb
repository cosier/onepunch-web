# app/models/oauth_authorization_code.rb
class OauthAuthorizationCode < ApplicationRecord
  belongs_to :oauth_application
  belongs_to :user

  # Validations
  validates :code, presence: true, uniqueness: true
  validates :redirect_uri, presence: true
  validates :code_challenge, presence: true
  validates :code_challenge_method, presence: true, inclusion: { in: %w[S256 plain] }
  validates :expires_at, presence: true

  # Callbacks
  before_validation :generate_code, on: :create
  before_validation :set_expiration, on: :create

  # Scopes
  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :revoked, -> { where.not(revoked_at: nil) }

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

  def scopes_list
    (scopes || "api").split(" ")
  end

  # PKCE validation
  def valid_code_verifier?(code_verifier)
    case code_challenge_method
    when "S256"
      # SHA256 hash of code_verifier should match code_challenge
      hashed = Base64.urlsafe_encode64(
        Digest::SHA256.digest(code_verifier),
        padding: false
      )
      hashed == code_challenge
    when "plain"
      # Plain text comparison (not recommended, but supported)
      code_verifier == code_challenge
    else
      false
    end
  end

  private

  def generate_code
    self.code ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at ||= 10.minutes.from_now
  end
end
