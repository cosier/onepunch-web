class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :first_name
      t.string :last_name
      t.string :password_digest
      t.string :google_uid
      t.string :avatar_url
      t.integer :role, default: 0
      t.datetime :last_sign_in_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :google_uid, unique: true, where: "google_uid IS NOT NULL"
  end
end
