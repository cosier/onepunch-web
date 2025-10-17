class CreateApiTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :api_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :token, null: false
      t.datetime :last_used_at
      t.datetime :expires_at
      t.datetime :revoked_at

      t.timestamps
    end
    add_index :api_tokens, :token, unique: true
    add_index :api_tokens, [:user_id, :revoked_at]
  end
end
