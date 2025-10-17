class AddPasswordTrackingToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :password_auto_generated, :boolean, default: false, null: false

    # Mark existing OAuth users as having auto-generated passwords
    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE users
          SET password_auto_generated = true
          WHERE google_uid IS NOT NULL
        SQL
      end
    end
  end
end
