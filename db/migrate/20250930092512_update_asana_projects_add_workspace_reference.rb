class UpdateAsanaProjectsAddWorkspaceReference < ActiveRecord::Migration[8.1]
  def change
    add_reference :asana_projects, :asana_workspace, foreign_key: true

    # Remove the old workspace_gid string column since we now have a proper reference
    remove_column :asana_projects, :asana_workspace_gid, :string if column_exists?(:asana_projects, :asana_workspace_gid)

    # Add index for common queries
    add_index :asana_projects, [:asana_workspace_id, :asana_gid]
  end
end
