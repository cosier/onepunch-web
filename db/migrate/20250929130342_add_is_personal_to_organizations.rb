class AddIsPersonalToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :is_personal, :boolean, default: false, null: false
    add_index :organizations, :is_personal
  end
end
