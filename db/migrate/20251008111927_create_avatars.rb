class CreateAvatars < ActiveRecord::Migration[8.1]
  def change
    create_table :avatars do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :source, null: false, default: 0
      t.string :source_url
      t.datetime :processed_at
      t.boolean :active, null: false, default: false

      t.timestamps
    end

    add_index :avatars, [:user_id, :active]
    add_index :avatars, :source
  end
end
