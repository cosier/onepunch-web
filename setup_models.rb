#!/usr/bin/env ruby
# Quick setup script to create initial models and migrations

puts "Creating initial models and migrations for OnePunch..."

# User model migration
user_migration = <<~RUBY
class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :first_name
      t.string :last_name
      t.string :password_digest
      t.string :google_uid
      t.string :avatar_url
      t.integer :role, default: 0
      t.datetime :last_sign_in_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :google_uid, unique: true, where: "google_uid IS NOT NULL"
  end
end
RUBY

# Organization model migration
org_migration = <<~RUBY
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
RUBY

# Membership model migration
membership_migration = <<~RUBY
class CreateMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.integer :role, default: 0
      t.datetime :joined_at

      t.timestamps
    end

    add_index :memberships, [:user_id, :organization_id], unique: true
  end
end
RUBY

# Project model migration
project_migration = <<~RUBY
class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.decimal :hourly_rate, precision: 10, scale: 2
      t.integer :status, default: 0
      t.string :color
      t.boolean :archived, default: false

      t.timestamps
    end

    add_index :projects, :archived
  end
end
RUBY

# Client model migration
client_migration = <<~RUBY
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
RUBY

# TimeEntry model migration
time_entry_migration = <<~RUBY
class CreateTimeEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :time_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.text :description
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :duration
      t.boolean :billable, default: true
      t.boolean :billed, default: false

      t.timestamps
    end

    add_index :time_entries, :started_at
    add_index :time_entries, :billable
    add_index :time_entries, :billed
  end
end
RUBY

# Invoice model migration
invoice_migration = <<~RUBY
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
RUBY

# Write migrations
timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i

migrations = [
  ["create_users", user_migration],
  ["create_organizations", org_migration],
  ["create_memberships", membership_migration],
  ["create_projects", project_migration],
  ["create_clients", client_migration],
  ["create_time_entries", time_entry_migration],
  ["create_invoices", invoice_migration]
]

migrations.each_with_index do |(name, content), index|
  filename = "#{timestamp + index}_#{name}.rb"
  path = "db/migrate/#{filename}"
  File.write(path, content)
  puts "Created migration: #{path}"
end

puts "\nMigrations created! Now run: rails db:create db:migrate"
