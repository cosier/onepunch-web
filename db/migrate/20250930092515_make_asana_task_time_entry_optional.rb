class MakeAsanaTaskTimeEntryOptional < ActiveRecord::Migration[8.1]
  def change
    # Tasks can exist without being assigned to time entries
    change_column_null :asana_tasks, :time_entry_id, true

    # Add cached fields for display without joins
    add_column :asana_tasks, :cached_project_name, :string
    add_column :asana_tasks, :cached_workspace_name, :string

    # Add indexes for better performance
    add_index :asana_tasks, :asana_gid, unique: true
    add_index :asana_tasks, :asana_project_gid
    add_index :asana_tasks, :completed
    add_index :asana_tasks, [:asana_project_gid, :completed]
  end
end
