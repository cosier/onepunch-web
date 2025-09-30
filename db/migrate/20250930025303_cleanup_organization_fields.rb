class CleanupOrganizationFields < ActiveRecord::Migration[8.0]
  def change
    # Remove fields from organizations - only keep name
    remove_column :organizations, :currency, :string
    remove_column :organizations, :timezone, :string
    remove_column :organizations, :size, :string

    # Add timezone to users (for personal settings)
    add_column :users, :timezone, :string, default: "UTC"
  end
end