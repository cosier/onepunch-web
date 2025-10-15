class AddPreferencesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :preferences, :json, default: {}, null: false
    add_index :users, :preferences, using: :gin
  end
end
