class CreateAsanaCredentials < ActiveRecord::Migration[8.1]
  def change
    create_table :asana_credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :access_token
      t.string :refresh_token
      t.datetime :expires_at
      t.string :workspace_gid
      t.string :workspace_name

      t.timestamps
    end
  end
end
