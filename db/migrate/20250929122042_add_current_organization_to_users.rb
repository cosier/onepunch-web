class AddCurrentOrganizationToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :current_organization, foreign_key: { to_table: :organizations }
    add_index :users, [:id, :current_organization_id]
  end
end
