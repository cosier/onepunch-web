class CreateOrganizationSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :organization_settings do |t|
      t.references :organization, null: false, foreign_key: true, index: { unique: true }
      t.string :invoice_prefix, default: "INV"
      t.integer :invoice_counter, default: 1
      t.decimal :default_hourly_rate, precision: 10, scale: 2
      t.decimal :tax_rate, precision: 5, scale: 2, default: 0
      t.string :currency, default: "USD"
      t.string :time_zone, default: "UTC"
      t.string :date_format, default: "%Y-%m-%d"
      t.boolean :notification_email, default: true
      t.boolean :notification_slack, default: false
      t.string :slack_webhook_url
      t.string :company_name
      t.text :company_address
      t.string :tax_id

      t.timestamps
    end
  end
end
