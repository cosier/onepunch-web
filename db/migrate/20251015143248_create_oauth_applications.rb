class CreateOauthApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_applications do |t|
      t.string :name, null: false
      t.string :client_id, null: false
      t.string :client_secret, null: false
      t.text :redirect_uris, null: false
      t.text :scopes, default: "api"
      t.boolean :confidential, default: false, null: false
      t.boolean :revoked, default: false, null: false
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end
    add_index :oauth_applications, :client_id, unique: true
  end
end
