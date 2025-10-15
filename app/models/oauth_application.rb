# app/models/oauth_application.rb
class OauthApplication < ApplicationRecord
  belongs_to :user, optional: true
  has_many :oauth_authorization_codes, dependent: :destroy
  has_many :oauth_access_tokens, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :client_id, presence: true, uniqueness: true
  validates :client_secret, presence: true
  validates :redirect_uris, presence: true

  # Callbacks
  before_validation :generate_credentials, on: :create

  # Scopes
  scope :active, -> { where(revoked: false) }
  scope :revoked, -> { where(revoked: true) }

  # Instance methods
  def revoke!
    update!(revoked: true)
  end

  def active?
    !revoked?
  end

  def redirect_uri_list
    redirect_uris.to_s.split("\n").map(&:strip).reject(&:blank?)
  end

  def valid_redirect_uri?(uri)
    redirect_uri_list.include?(uri)
  end

  def scopes_list
    (scopes || "api").split(" ")
  end

  private

  def generate_credentials
    self.client_id ||= SecureRandom.urlsafe_base64(32)
    self.client_secret ||= SecureRandom.urlsafe_base64(32)
  end
end
