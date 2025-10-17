class AsanaTask < ApplicationRecord
  belongs_to :time_entry, optional: true

  validates :asana_gid, presence: true, uniqueness: true
  validates :name, presence: true

  scope :unassigned, -> { where(time_entry_id: nil) }
  scope :assigned, -> { where.not(time_entry_id: nil) }
  scope :by_workspace, ->(workspace_name) { where(cached_workspace_name: workspace_name) }
  scope :by_project_gid, ->(gid) { where(asana_project_gid: gid) }
  scope :incomplete, -> { where(completed: [false, nil]) }
  scope :search, ->(query) { where("name LIKE ?", "%#{sanitize_sql_like(query)}%") if query.present? }

  # Sync tasks from Asana for a specific project
  def self.sync_from_asana(user, workspace, asana_project, asana_api_service)
    return [] unless user.asana_connected?

    tasks_data = asana_api_service.fetch_tasks(asana_project.asana_gid)

    tasks_data.map do |asana_task_data|
      # Find existing or create new AsanaTask record
      task = find_or_initialize_by(asana_gid: asana_task_data['gid'])

      task.assign_attributes(
        name: asana_task_data['name'],
        asana_project_gid: asana_project.asana_gid,
        completed: asana_task_data['completed'],
        due_date: asana_task_data['due_on'],
        assignee_gid: asana_task_data.dig('assignee', 'gid'),
        cached_project_name: asana_project.name,
        cached_workspace_name: workspace.name
      )

      task.save!
      task
    end
  rescue => e
    Rails.logger.error "Asana task sync error: #{e.message}"
    []
  end

  # Get tasks grouped by workspace and project for dropdowns
  def self.grouped_for_select(user)
    return [] unless user.asana_connected?

    tasks = unassigned.incomplete.order(:cached_workspace_name, :cached_project_name, :name)

    tasks.group_by(&:cached_workspace_name).transform_values do |workspace_tasks|
      workspace_tasks.group_by(&:cached_project_name).transform_values do |project_tasks|
        project_tasks.map { |t| [t.display_name, t.asana_gid] }
      end
    end
  end

  def display_name
    parts = [name]
    parts << "(due: #{due_date.strftime('%m/%d')})" if due_date.present?
    parts.join(" ")
  end
end
