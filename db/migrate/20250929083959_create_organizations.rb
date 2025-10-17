class CreateOrganizations < ActiveRecord::Migration[8.0]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :billing_email
      t.text :address
      t.string :tax_id
      t.string :currency, default: 'USD'
      t.string :timezone, default: 'UTC'

      t.timestamps
    end

    add_index :organizations, :slug, unique: true
  end
end
