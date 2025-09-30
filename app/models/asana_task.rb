class AsanaTask < ApplicationRecord
  belongs_to :time_entry

  validates :asana_gid, presence: true, uniqueness: true
  validates :name, presence: true

  # Sync tasks from Asana for a specific project
  def self.sync_from_asana(user, asana_project)
    return unless user.asana_connected?

    credential = user.asana_credential
    response = HTTParty.get("https://app.asana.com/api/1.0/tasks",
      headers: {
        'Authorization' => "Bearer #{credential.access_token}"
      },
      query: {
        project: asana_project.asana_gid,
        opt_fields: 'name,completed,due_on,assignee.gid'
      }
    )

    tasks_data = JSON.parse(response.body).dig('data')
    return [] unless tasks_data

    tasks_data.map do |asana_task|
      # Find existing AsanaTask record
      task = find_or_initialize_by(asana_gid: asana_task['gid'])

      task.assign_attributes(
        name: asana_task['name'],
        asana_project_gid: asana_project.asana_gid,
        completed: asana_task['completed'],
        due_date: asana_task['due_on'],
        assignee_gid: asana_task.dig('assignee', 'gid')
      )

      # Only save if we have a time_entry association
      task.save! if task.time_entry_id.present?

      task
    end
  rescue => e
    Rails.logger.error "Asana task sync error: #{e.message}"
    []
  end
end
