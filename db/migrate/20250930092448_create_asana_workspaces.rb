class CreateAsanaWorkspaces < ActiveRecord::Migration[8.1]
  def change
    create_table :asana_workspaces do |t|
      t.references :user, null: false, foreign_key: true
      t.string :asana_gid, null: false
      t.string :name, null: false
      t.boolean :is_organization, default: false
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :asana_workspaces, :asana_gid, unique: true
    add_index :asana_workspaces, [:user_id, :asana_gid], unique: true
  end
end
