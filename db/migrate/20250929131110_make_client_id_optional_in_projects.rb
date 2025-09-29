class MakeClientIdOptionalInProjects < ActiveRecord::Migration[8.1]
  def change
    change_column_null :projects, :client_id, true
  end
end
