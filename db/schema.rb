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

ActiveRecord::Schema[8.0].define(version: 2025_08_08_165758) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "node_supplies", force: :cascade do |t|
    t.string "provider_id"
    t.string "region"
    t.string "zone"
    t.string "type_name"
    t.integer "capacity", default: 0
    t.integer "millicents_per_hour"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id", "region", "zone", "type_name"], name: "unique_node_supply_dimensions", unique: true
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "order_id"
    t.integer "project_id"
    t.integer "price_cents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["project_id"], name: "index_order_items_on_project_id"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "user_id"
    t.string "stripe_session_id"
    t.string "receipt_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "project_benchmarks", force: :cascade do |t|
    t.integer "project_id"
    t.string "node_provider_id"
    t.string "node_type_name"
    t.json "sample_settings"
    t.json "timing"
    t.integer "expected_render_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_benchmarks_on_project_id"
  end

  create_table "project_checks", force: :cascade do |t|
    t.integer "project_id"
    t.json "stats"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_checks_on_project_id"
  end

  create_table "project_renders", force: :cascade do |t|
    t.integer "project_id"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_renders_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.integer "upload_id"
    t.string "uuid"
    t.string "status"
    t.string "blend_file"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["upload_id"], name: "index_projects_on_upload_id"
    t.index ["uuid"], name: "index_projects_on_uuid", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings_revisions", force: :cascade do |t|
    t.integer "project_id"
    t.json "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_settings_revisions_on_project_id"
  end

  create_table "uploads", force: :cascade do |t|
    t.string "uuid"
    t.integer "user_id"
    t.string "guest_email_address"
    t.string "guest_session_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_uploads_on_user_id"
    t.index ["uuid"], name: "index_uploads_on_uuid", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest"
    t.boolean "email_address_verified", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "workflows", force: :cascade do |t|
    t.string "uuid"
    t.string "status"
    t.string "workflowable_type"
    t.integer "workflowable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_workflows_on_uuid", unique: true
    t.index ["workflowable_type", "workflowable_id"], name: "index_workflows_on_workflowable"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "sessions", "users"
end
