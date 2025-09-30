class AsanaSyncJob < ApplicationJob
  queue_as :default

  # Sync all Asana data for a user: workspaces, projects, and tasks
  def perform(user_id, sync_tasks: true)
    user = User.find(user_id)
    return unless user.asana_connected?

    credential = user.asana_credential
    api_service = AsanaApiService.new(credential)

    # Step 1: Sync workspaces
    workspaces = AsanaWorkspace.sync_workspaces(user, api_service)
    Rails.logger.info "Synced #{workspaces.count} workspaces for user #{user.id}"

    # Step 2: Sync projects for each workspace
    workspaces.each do |workspace|
      projects = workspace.sync_projects(api_service)
      Rails.logger.info "Synced #{projects.count} projects for workspace #{workspace.name}"

      # Step 3: Sync tasks for each project (if enabled)
      if sync_tasks
        projects.each do |project|
          tasks = project.sync_tasks(api_service)
          Rails.logger.info "Synced #{tasks.count} tasks for project #{project.name}"
        end
      end
    end

    Rails.logger.info "Asana sync completed for user #{user.id}"
  rescue AsanaApiService::RateLimitError => e
    # Retry after the specified time
    retry_after = e.message.match(/(\d+) seconds/)[1].to_i rescue 60
    retry_job wait: retry_after.seconds
  rescue AsanaApiService::AuthenticationError => e
    Rails.logger.error "Authentication failed for user #{user_id}: #{e.message}"
    # Don't retry - token is invalid
  rescue => e
    Rails.logger.error "Asana sync failed for user #{user_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise # Will trigger retry based on ActiveJob configuration
  end
end
