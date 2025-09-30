class AsanaProject < ApplicationRecord
  belongs_to :project
  belongs_to :asana_workspace

  validates :asana_gid, presence: true, uniqueness: true
  validates :name, presence: true

  scope :by_workspace, ->(workspace) { where(asana_workspace: workspace) }
  scope :recently_synced, -> { where("last_synced_at > ?", 1.hour.ago) }

  # Sync projects from Asana for a specific workspace
  def self.sync_from_asana(user, workspace, asana_api_service)
    return [] unless user.asana_connected?

    projects_data = asana_api_service.fetch_projects(workspace.asana_gid)

    projects_data.map do |asana_project_data|
      # Find or create OnePunch project
      project = user.current_organization.projects.find_or_initialize_by(
        name: asana_project_data['name']
      )

      project.save! if project.new_record?

      # Create or update AsanaProject link
      asana_proj = find_or_initialize_by(
        asana_gid: asana_project_data['gid'],
        asana_workspace: workspace
      )

      asana_proj.update!(
        project: project,
        name: asana_project_data['name'],
        last_synced_at: Time.current
      )

      asana_proj
    end
  rescue => e
    Rails.logger.error "Asana project sync error: #{e.message}"
    []
  end

  # Sync tasks for this project
  def sync_tasks(asana_api_service)
    AsanaTask.sync_from_asana(asana_workspace.user, asana_workspace, self, asana_api_service)
  end
end