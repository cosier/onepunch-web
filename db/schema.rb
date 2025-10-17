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

ActiveRecord::Schema[8.1].define(version: 2025_10_17_115224) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "api_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.datetime "last_used_at"
    t.string "name", null: false
    t.datetime "revoked_at"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["token"], name: "index_api_tokens_on_token", unique: true
    t.index ["user_id", "revoked_at"], name: "index_api_tokens_on_user_id_and_revoked_at"
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "asana_credentials", force: :cascade do |t|
    t.string "access_token"
    t.string "asana_user_gid"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "refresh_token"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["asana_user_gid"], name: "index_asana_credentials_on_asana_user_gid", unique: true
    t.index ["user_id"], name: "index_asana_credentials_on_user_id"
  end

  create_table "asana_projects", force: :cascade do |t|
    t.string "asana_gid"
    t.integer "asana_workspace_id"
    t.datetime "created_at", null: false
    t.datetime "last_synced_at"
    t.string "name"
    t.integer "project_id", null: false
    t.datetime "updated_at", null: false
    t.index ["asana_workspace_id", "asana_gid"], name: "index_asana_projects_on_asana_workspace_id_and_asana_gid"
    t.index ["asana_workspace_id"], name: "index_asana_projects_on_asana_workspace_id"
    t.index ["project_id"], name: "index_asana_projects_on_project_id"
  end

  create_table "asana_tasks", force: :cascade do |t|
    t.string "asana_gid"
    t.string "asana_project_gid"
    t.string "assignee_gid"
    t.string "cached_project_name"
    t.string "cached_workspace_name"
    t.boolean "completed"
    t.datetime "created_at", null: false
    t.date "due_date"
    t.string "name"
    t.integer "time_entry_id"
    t.datetime "updated_at", null: false
    t.index ["asana_gid"], name: "index_asana_tasks_on_asana_gid", unique: true
    t.index ["asana_project_gid", "completed"], name: "index_asana_tasks_on_asana_project_gid_and_completed"
    t.index ["asana_project_gid"], name: "index_asana_tasks_on_asana_project_gid"
    t.index ["completed"], name: "index_asana_tasks_on_completed"
    t.index ["time_entry_id"], name: "index_asana_tasks_on_time_entry_id"
  end

  create_table "asana_workspaces", force: :cascade do |t|
    t.string "asana_gid", null: false
    t.datetime "created_at", null: false
    t.boolean "is_organization", default: false
    t.datetime "last_synced_at"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["asana_gid"], name: "index_asana_workspaces_on_asana_gid", unique: true
    t.index ["user_id", "asana_gid"], name: "index_asana_workspaces_on_user_id_and_asana_gid", unique: true
    t.index ["user_id"], name: "index_asana_workspaces_on_user_id"
  end

  create_table "avatars", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "processed_at"
    t.integer "source", default: 0, null: false
    t.string "source_url"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["source"], name: "index_avatars_on_source"
    t.index ["user_id", "active"], name: "index_avatars_on_user_id_and_active"
    t.index ["user_id"], name: "index_avatars_on_user_id"
  end

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

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "last_used_at"
    t.integer "oauth_application_id", null: false
    t.string "refresh_token"
    t.datetime "revoked_at"
    t.text "scopes"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["expires_at"], name: "index_oauth_access_tokens_on_expires_at"
    t.index ["oauth_application_id", "user_id"], name: "index_oauth_access_tokens_on_oauth_application_id_and_user_id"
    t.index ["oauth_application_id"], name: "index_oauth_access_tokens_on_oauth_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_oauth_access_tokens_on_user_id"
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "client_id", null: false
    t.string "client_secret", null: false
    t.boolean "confidential", default: false, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "redirect_uris", null: false
    t.boolean "revoked", default: false, null: false
    t.text "scopes", default: "api"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["client_id"], name: "index_oauth_applications_on_client_id", unique: true
    t.index ["user_id"], name: "index_oauth_applications_on_user_id"
  end

  create_table "oauth_authorization_codes", force: :cascade do |t|
    t.string "code", null: false
    t.string "code_challenge", null: false
    t.string "code_challenge_method", default: "S256", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.integer "oauth_application_id", null: false
    t.string "redirect_uri"
    t.datetime "revoked_at"
    t.text "scopes"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["code"], name: "index_oauth_authorization_codes_on_code", unique: true
    t.index ["expires_at"], name: "index_oauth_authorization_codes_on_expires_at"
    t.index ["oauth_application_id", "user_id"], name: "idx_on_oauth_application_id_user_id_7de793706d"
    t.index ["oauth_application_id"], name: "index_oauth_authorization_codes_on_oauth_application_id"
    t.index ["user_id"], name: "index_oauth_authorization_codes_on_user_id"
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
    t.boolean "password_auto_generated", default: false, null: false
    t.string "password_digest"
    t.json "preferences", default: {}, null: false
    t.integer "role", default: 0
    t.string "timezone", default: "UTC"
    t.datetime "updated_at", null: false
    t.index ["current_organization_id"], name: "index_users_on_current_organization_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true, where: "google_uid IS NOT NULL"
    t.index ["id", "current_organization_id"], name: "index_users_on_id_and_current_organization_id"
    t.index ["preferences"], name: "index_users_on_preferences"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "asana_credentials", "users"
  add_foreign_key "asana_projects", "asana_workspaces"
  add_foreign_key "asana_projects", "projects"
  add_foreign_key "asana_tasks", "time_entries"
  add_foreign_key "asana_workspaces", "users"
  add_foreign_key "avatars", "users"
  add_foreign_key "clients", "organizations"
  add_foreign_key "invitations", "organizations"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "invoice_line_items", "invoices"
  add_foreign_key "invoices", "clients"
  add_foreign_key "invoices", "organizations"
  add_foreign_key "invoices", "projects"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "oauth_access_tokens", "oauth_applications"
  add_foreign_key "oauth_access_tokens", "users"
  add_foreign_key "oauth_applications", "users"
  add_foreign_key "oauth_authorization_codes", "oauth_applications"
  add_foreign_key "oauth_authorization_codes", "users"
  add_foreign_key "organization_settings", "organizations"
  add_foreign_key "projects", "clients"
  add_foreign_key "projects", "organizations"
  add_foreign_key "time_entries", "projects"
  add_foreign_key "time_entries", "users"
  add_foreign_key "users", "organizations", column: "current_organization_id"
end
