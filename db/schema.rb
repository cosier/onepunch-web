# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_09_30_030939) do
  create_table "clients", force: :cascade do |t|
    t.text "address"
    t.string "company"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.integer "organization_id", null: false
    t.string "phone"
    t.string "tax_id"
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_clients_on_organization_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "expires_at"
    t.integer "invited_by_id"
    t.integer "organization_id", null: false
    t.string "role", default: "member"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["organization_id", "email"], name: "index_invitations_on_organization_id_and_email"
    t.index ["organization_id"], name: "index_invitations_on_organization_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "invoice_line_items", force: :cascade do |t|
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "invoice_id", null: false
    t.decimal "quantity"
    t.text "time_entry_ids"
    t.decimal "unit_price"
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_line_items_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.integer "client_id", null: false
    t.datetime "created_at", null: false
    t.date "due_at"
    t.date "issued_at"
    t.text "notes"
    t.string "number"
    t.integer "organization_id", null: false
    t.date "paid_at"
    t.integer "project_id"
    t.integer "status", default: 0
    t.decimal "subtotal", precision: 10, scale: 2
    t.decimal "tax_amount", precision: 10, scale: 2
    t.decimal "tax_rate", precision: 5, scale: 2
    t.decimal "total", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_invoices_on_client_id"
    t.index ["number"], name: "index_invoices_on_number"
    t.index ["organization_id"], name: "index_invoices_on_organization_id"
    t.index ["project_id"], name: "index_invoices_on_project_id"
    t.index ["status"], name: "index_invoices_on_status"
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "joined_at"
    t.integer "organization_id", null: false
    t.integer "role", default: 0
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["user_id", "organization_id"], name: "index_memberships_on_user_id_and_organization_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "organization_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency"
    t.string "date_format"
    t.decimal "default_hourly_rate"
    t.integer "invoice_counter"
    t.string "invoice_prefix"
    t.boolean "notification_email"
    t.boolean "notification_slack"
    t.integer "organization_id", null: false
    t.decimal "tax_rate"
    t.string "time_zone"
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_organization_settings_on_organization_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.text "address"
    t.string "billing_email"
    t.datetime "created_at", null: false
    t.string "industry"
    t.string "logo_url"
    t.string "name", null: false
    t.datetime "onboarded_at"
    t.boolean "personal", default: false, null: false
    t.text "settings"
    t.string "slug", null: false
    t.string "subscription_status", default: "trial"
    t.string "tax_id"
    t.datetime "trial_ends_at"
    t.datetime "updated_at", null: false
    t.string "website"
    t.index ["personal"], name: "index_organizations_on_personal"
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.boolean "archived", default: false
    t.integer "client_id"
    t.string "color"
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "hourly_rate", precision: 10, scale: 2
    t.string "name", null: false
    t.integer "organization_id", null: false
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.index ["archived"], name: "index_projects_on_archived"
    t.index ["client_id"], name: "index_projects_on_client_id"
    t.index ["organization_id"], name: "index_projects_on_organization_id"
  end

  create_table "summaries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "metadata", default: {}
    t.string "status", default: "pending"
    t.text "summarized_text"
    t.text "text_to_summarize"
    t.string "unique_slug", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_summaries_on_created_at"
    t.index ["status"], name: "index_summaries_on_status"
    t.index ["unique_slug"], name: "index_summaries_on_unique_slug", unique: true
  end

  create_table "time_entries", force: :cascade do |t|
    t.boolean "billable", default: true
    t.boolean "billed", default: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "duration"
    t.datetime "ended_at"
    t.integer "project_id", null: false
    t.datetime "started_at"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["billable"], name: "index_time_entries_on_billable"
    t.index ["billed"], name: "index_time_entries_on_billed"
    t.index ["project_id"], name: "index_time_entries_on_project_id"
    t.index ["started_at"], name: "index_time_entries_on_started_at"
    t.index ["user_id"], name: "index_time_entries_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.integer "current_organization_id"
    t.string "email", null: false
    t.string "first_name"
    t.string "google_uid"
    t.string "last_name"
    t.datetime "last_sign_in_at"
    t.string "password_digest"
    t.integer "role", default: 0
    t.string "timezone", default: "UTC"
    t.datetime "updated_at", null: false
    t.index ["current_organization_id"], name: "index_users_on_current_organization_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true, where: "google_uid IS NOT NULL"
    t.index ["id", "current_organization_id"], name: "index_users_on_id_and_current_organization_id"
  end

  add_foreign_key "clients", "organizations"
  add_foreign_key "invitations", "organizations"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "invoice_line_items", "invoices"
  add_foreign_key "invoices", "clients"
  add_foreign_key "invoices", "organizations"
  add_foreign_key "invoices", "projects"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "organization_settings", "organizations"
  add_foreign_key "projects", "clients"
  add_foreign_key "projects", "organizations"
  add_foreign_key "time_entries", "projects"
  add_foreign_key "time_entries", "users"
  add_foreign_key "users", "organizations", column: "current_organization_id"
end
