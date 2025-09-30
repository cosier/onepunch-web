class RemoveWorkspaceFieldsFromAsanaCredentials < ActiveRecord::Migration[8.1]
  def change
    # Safely remove workspace fields - data will be migrated to AsanaWorkspace model
    remove_column :asana_credentials, :workspace_gid, :string if column_exists?(:asana_credentials, :workspace_gid)
    remove_column :asana_credentials, :workspace_name, :string if column_exists?(:asana_credentials, :workspace_name)
  end
end
