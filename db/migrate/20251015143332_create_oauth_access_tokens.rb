class CreateOauthAccessTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_access_tokens do |t|
      t.string :token, null: false
      t.string :refresh_token
      t.references :oauth_application, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :scopes
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.datetime :last_used_at

      t.timestamps
    end
    add_index :oauth_access_tokens, :token, unique: true
    add_index :oauth_access_tokens, :refresh_token, unique: true
    add_index :oauth_access_tokens, [:oauth_application_id, :user_id]
    add_index :oauth_access_tokens, :expires_at
  end
end
