class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.references :project, foreign_key: true
      t.string :number
      t.integer :status, default: 0
      t.date :issued_at
      t.date :due_at
      t.date :paid_at
      t.decimal :subtotal, precision: 10, scale: 2
      t.decimal :tax_rate, precision: 5, scale: 2
      t.decimal :tax_amount, precision: 10, scale: 2
      t.decimal :total, precision: 10, scale: 2
      t.text :notes

      t.timestamps
    end

    add_index :invoices, :number
    add_index :invoices, :status
  end
end
