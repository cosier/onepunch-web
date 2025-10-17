class CreateAsanaProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :asana_projects do |t|
      t.references :project, null: false, foreign_key: true
      t.string :asana_gid
      t.string :name
      t.string :asana_workspace_gid
      t.datetime :last_synced_at

      t.timestamps
    end
  end
end
