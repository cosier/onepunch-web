require 'open-uri'
require 'net/http'

class DownloadAvatarJob < ApplicationJob
  queue_as :default

  retry_on OpenURI::HTTPError, wait: 5.seconds, attempts: 3
  retry_on Net::OpenTimeout, wait: 5.seconds, attempts: 3

  def perform(user)
    return unless user.avatar_url.present?
    return if user.active_avatar&.source_url == user.avatar_url

    begin
      # Download the image from the OAuth provider
      downloaded_image = URI.open(user.avatar_url, read_timeout: 10)

      # Extract filename and content type
      filename = "avatar-#{user.id}-#{Time.current.to_i}.jpg"
      content_type = downloaded_image.content_type || 'image/jpeg'

      # Create or update avatar record
      avatar = user.avatars.find_or_initialize_by(
        source: 'google',
        source_url: user.avatar_url
      )

      # Attach the image to the avatar
      avatar.image.attach(
        io: downloaded_image,
        filename: filename,
        content_type: content_type
      )

      # Save and activate the avatar
      avatar.processed_at = Time.current
      avatar.save!
      avatar.activate!

      Rails.logger.info "Successfully downloaded and attached avatar for user #{user.id}"
    rescue => e
      Rails.logger.error "Failed to download avatar for user #{user.id}: #{e.message}"
      raise
    end
  end
end