class CreateAsanaTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :asana_tasks do |t|
      t.references :time_entry, null: false, foreign_key: true
      t.string :asana_gid
      t.string :name
      t.string :asana_project_gid
      t.boolean :completed
      t.date :due_date
      t.string :assignee_gid

      t.timestamps
    end
  end
end
