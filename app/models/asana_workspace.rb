class AsanaWorkspace < ApplicationRecord
  belongs_to :user
  has_many :asana_projects, dependent: :destroy

  validates :asana_gid, presence: true, uniqueness: true
  validates :name, presence: true

  scope :by_user, ->(user) { where(user: user) }
  scope :recently_synced, -> { where("last_synced_at > ?", 1.hour.ago) }

  # Sync all workspaces for a user from Asana API
  def self.sync_workspaces(user, asana_api_service)
    return [] unless user.asana_connected?

    workspaces_data = asana_api_service.fetch_workspaces

    workspaces_data.map do |workspace_data|
      workspace = find_or_initialize_by(
        user: user,
        asana_gid: workspace_data['gid']
      )

      workspace.update!(
        name: workspace_data['name'],
        is_organization: workspace_data['is_organization'] || false,
        last_synced_at: Time.current
      )

      workspace
    end
  rescue => e
    Rails.logger.error "Workspace sync error: #{e.message}"
    []
  end

  # Sync projects for this workspace
  def sync_projects(asana_api_service)
    AsanaProject.sync_from_asana(user, self, asana_api_service)
  end
end
