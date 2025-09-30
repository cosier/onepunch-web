class AsanaProject < ApplicationRecord
  belongs_to :project

  validates :asana_gid, presence: true, uniqueness: true
  validates :name, presence: true

  # Sync projects from Asana to local projects
  def self.sync_from_asana(user)
    return unless user.asana_connected?

    credential = user.asana_credential
    response = HTTParty.get("https://app.asana.com/api/1.0/projects",
      headers: {
        'Authorization' => "Bearer #{credential.access_token}"
      },
      query: {
        workspace: credential.workspace_gid,
        archived: false
      }
    )

    projects_data = JSON.parse(response.body).dig('data')
    return [] unless projects_data

    projects_data.map do |asana_project|
      # Find or create OnePunch project
      project = user.current_organization.projects.find_or_initialize_by(
        name: asana_project['name']
      )

      if project.new_record?
        project.save!
      end

      # Create or update AsanaProject link
      asana_proj = find_or_initialize_by(
        asana_gid: asana_project['gid'],
        project: project
      )

      asana_proj.update!(
        name: asana_project['name'],
        asana_workspace_gid: credential.workspace_gid,
        last_synced_at: Time.current
      )

      asana_proj
    end
  rescue => e
    Rails.logger.error "Asana project sync error: #{e.message}"
    []
  end
end