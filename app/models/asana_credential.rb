class AsanaCredential < ApplicationRecord
  belongs_to :user

  validates :access_token, presence: true
  validates :user_id, uniqueness: true
  validates :asana_user_gid, uniqueness: { message: "This Asana account is already connected to another OnePunch account" }, allow_nil: true

  # Check if token is expired
  def expired?
    expires_at && expires_at < Time.current
  end

  # Refresh the access token if needed
  def refresh_token!
    return unless refresh_token.present?

    asana_api_service = AsanaApiService.new(self)
    asana_api_service.refresh_access_token!
  rescue => e
    Rails.logger.error "Token refresh error: #{e.message}"
    false
  end

  # Make an API call with this credential
  def api_call(path, params = {})
    asana_api_service = AsanaApiService.new(self)
    asana_api_service.get(path, params)
  end
end
