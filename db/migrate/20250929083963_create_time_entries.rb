class CreateTimeEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :time_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.text :description
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :duration
      t.boolean :billable, default: true
      t.boolean :billed, default: false

      t.timestamps
    end

    add_index :time_entries, :started_at
    add_index :time_entries, :billable
    add_index :time_entries, :billed
  end
end
