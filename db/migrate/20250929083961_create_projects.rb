class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.decimal :hourly_rate, precision: 10, scale: 2
      t.integer :status, default: 0
      t.string :color
      t.boolean :archived, default: false

      t.timestamps
    end

    add_index :projects, :archived
  end
end
