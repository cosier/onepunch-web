class RenameIsPersonalToPersonal < ActiveRecord::Migration[8.0]
  def change
    rename_column :organizations, :is_personal, :personal
  end
end
