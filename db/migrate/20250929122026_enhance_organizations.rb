class EnhanceOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :logo_url, :string
    add_column :organizations, :website, :string
    add_column :organizations, :industry, :string
    add_column :organizations, :size, :string
    add_column :organizations, :onboarded_at, :datetime
    add_column :organizations, :trial_ends_at, :datetime
    add_column :organizations, :subscription_status, :string, default: 'trial'
    add_column :organizations, :settings, :text
  end
end
