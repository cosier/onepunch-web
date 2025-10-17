class CreateInvoiceLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_line_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.text :description
      t.decimal :quantity
      t.decimal :unit_price
      t.decimal :amount
      t.text :time_entry_ids

      t.timestamps
    end
  end
end
