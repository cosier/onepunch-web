class AddAsanaUserGidToAsanaCredentials < ActiveRecord::Migration[8.1]
  def change
    add_column :asana_credentials, :asana_user_gid, :string
    add_index :asana_credentials, :asana_user_gid, unique: true
  end
end
