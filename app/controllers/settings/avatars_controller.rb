class Settings::AvatarsController < ApplicationController
  before_action :authenticate_user!

  def update
    if params[:avatar].present?
      # Create new avatar record
      avatar = current_user.avatars.build(
        source: 'uploaded',
        processed_at: Time.current
      )

      # Attach the uploaded image
      avatar.image.attach(params[:avatar])

      if avatar.save
        # Activate this avatar (deactivates others)
        avatar.activate!

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace("avatar-preview",
                partial: "settings/avatars/preview",
                locals: { user: current_user }),
              turbo_stream.append("flash",
                partial: "shared/flash",
                locals: { flash: { notice: "Avatar updated successfully!" } }),
              turbo_stream.append_all("body",
                "<script>document.dispatchEvent(new CustomEvent('avatar:uploaded')); setTimeout(() => document.currentScript.remove(), 0)</script>")
            ]
          end
          format.html { redirect_to settings_account_path, notice: "Avatar updated successfully!" }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace("flash-messages",
              partial: "shared/flash",
              locals: { flash: { alert: "Failed to update avatar: #{avatar.errors.full_messages.join(', ')}" } })
          end
          format.html { redirect_to settings_account_path, alert: "Failed to update avatar" }
        end
      end
    else
      redirect_to settings_account_path, alert: "Please select an image to upload"
    end
  end

  def destroy
    if current_user.active_avatar&.destroy
      # Fall back to OAuth avatar if available
      if current_user.avatar_url.present?
        oauth_avatar = current_user.avatars.find_or_create_by(
          source: 'google',
          source_url: current_user.avatar_url
        )
        oauth_avatar.activate!
      end

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("avatar-preview",
              partial: "settings/avatars/preview",
              locals: { user: current_user }),
            turbo_stream.replace("flash-messages",
              partial: "shared/flash",
              locals: { flash: { notice: "Avatar removed successfully!" } })
          ]
        end
        format.html { redirect_to settings_account_path, notice: "Avatar removed successfully!" }
      end
    else
      redirect_to settings_account_path, alert: "Failed to remove avatar"
    end
  end

  def revert
    # Revert to OAuth avatar
    if current_user.avatar_url.present?
      oauth_avatar = current_user.avatars.find_or_create_by(
        source: 'google',
        source_url: current_user.avatar_url
      )

      # Queue download if not already downloaded
      if !oauth_avatar.image.attached?
        DownloadAvatarJob.perform_later(current_user)
      end

      oauth_avatar.activate!

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("avatar-preview",
              partial: "settings/avatars/preview",
              locals: { user: current_user }),
            turbo_stream.replace("flash-messages",
              partial: "shared/flash",
              locals: { flash: { notice: "Reverted to Google profile picture!" } })
          ]
        end
        format.html { redirect_to settings_account_path, notice: "Reverted to Google profile picture!" }
      end
    else
      redirect_to settings_account_path, alert: "No Google profile picture available"
    end
  end
end