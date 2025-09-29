class CreateClients < ActiveRecord::Migration[8.0]
  def change
    create_table :clients do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email
      t.string :company
      t.string :phone
      t.text :address
      t.string :tax_id

      t.timestamps
    end
  end
end
