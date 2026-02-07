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

ActiveRecord::Schema[8.2].define(version: 2026_02_07_120000) do
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

  create_table "affiliate_monthly_stats", force: :cascade do |t|
    t.integer "affiliate_id", null: false
    t.datetime "created_at", null: false
    t.integer "month", null: false
    t.datetime "paid_out_at"
    t.integer "rewards_cents", default: 0, null: false
    t.integer "sales_cents", default: 0, null: false
    t.integer "signups", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "visits", default: 0, null: false
    t.integer "year", null: false
    t.index ["affiliate_id", "year", "month"], name: "idx_on_affiliate_id_year_month_5f1d0c472d", unique: true
    t.index ["affiliate_id"], name: "index_affiliate_monthly_stats_on_affiliate_id"
  end

  create_table "affiliates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "landing_page_id", null: false
    t.json "payout_method_details"
    t.datetime "payout_onboarded_at"
    t.integer "reward_percent", default: 10, null: false
    t.integer "reward_window_months", default: 12, null: false
    t.string "stripe_account_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["landing_page_id"], name: "index_affiliates_on_landing_page_id"
    t.index ["stripe_account_id"], name: "index_affiliates_on_stripe_account_id", unique: true
    t.index ["user_id"], name: "index_affiliates_on_user_id", unique: true
  end

  create_table "api_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_used_at"
    t.string "name", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
  end

  create_table "articles", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.text "excerpt"
    t.text "image_url"
    t.datetime "published_at"
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["slug"], name: "index_articles_on_slug", unique: true
    t.index ["user_id"], name: "index_articles_on_user_id"
  end

  create_table "blender_scenes", force: :cascade do |t|
    t.json "camera", null: false
    t.datetime "created_at", null: false
    t.json "file_output", null: false
    t.json "frame_range", null: false
    t.string "name", null: false
    t.json "post_processing", null: false
    t.integer "project_id", null: false
    t.json "resolution", null: false
    t.json "sampling", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_blender_scenes_on_project_id"
  end

  create_table "credit_entries", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.integer "order_id"
    t.string "reason"
    t.integer "refund_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["created_at"], name: "index_credit_entries_on_created_at"
    t.index ["order_id"], name: "index_credit_entries_on_order_id"
    t.index ["reason", "created_at"], name: "index_credit_entries_on_reason_and_created_at"
    t.index ["refund_id"], name: "index_credit_entries_on_refund_id"
    t.index ["user_id", "reason", "created_at"], name: "index_credit_entries_on_user_id_reason_created_at"
    t.index ["user_id"], name: "index_credit_entries_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.integer "request_id", null: false
    t.integer "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["request_id"], name: "index_events_on_request_id"
    t.index ["resource_type", "resource_id"], name: "index_events_on_resource"
  end

  create_table "faqs", force: :cascade do |t|
    t.text "answer"
    t.integer "clicks", default: 0
    t.datetime "created_at", null: false
    t.string "question"
    t.datetime "updated_at", null: false
  end

  create_table "landing_pages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_landing_pages_on_slug", unique: true
  end

  create_table "node_supplies", force: :cascade do |t|
    t.integer "capacity", default: 0
    t.datetime "created_at", null: false
    t.integer "millicents_per_hour"
    t.string "provider_id", null: false
    t.string "region", null: false
    t.string "type_name", null: false
    t.datetime "updated_at", null: false
    t.string "zone", null: false
    t.index ["provider_id", "region", "zone", "type_name"], name: "unique_node_supply_attributes", unique: true
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "cash_cents", null: false
    t.datetime "created_at", null: false
    t.integer "credit_cents", null: false
    t.integer "order_id", null: false
    t.json "preferences"
    t.integer "project_id", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["project_id"], name: "index_order_items_on_project_id"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "cash_cents"
    t.datetime "created_at", null: false
    t.integer "credit_cents"
    t.string "guest_email_address"
    t.string "guest_session_id"
    t.string "stripe_payment_intent_id"
    t.string "stripe_session_id"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id", "created_at"], name: "index_orders_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "page_variants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "landing_page_id", null: false
    t.json "sections", null: false
    t.datetime "updated_at", null: false
    t.index ["landing_page_id"], name: "index_page_variants_on_landing_page_id"
  end

  create_table "project_benchmarks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "project_id", null: false
    t.json "sample_settings", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_benchmarks_on_project_id"
  end

  create_table "project_blend_checks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "project_id", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_blend_checks_on_project_id"
  end

  create_table "project_renders", force: :cascade do |t|
    t.integer "cents_per_gigasample"
    t.datetime "created_at", null: false
    t.integer "frame_count"
    t.integer "max_samples"
    t.integer "pixel_count"
    t.integer "price_cents"
    t.integer "project_id", null: false
    t.integer "resolution_x"
    t.integer "resolution_y"
    t.bigint "total_samples"
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_renders_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "blend_filepath"
    t.datetime "created_at", null: false
    t.integer "current_blender_scene_id"
    t.datetime "deleted_at"
    t.string "name"
    t.integer "order_id"
    t.integer "price_cents"
    t.datetime "stage_updated_at"
    t.string "status"
    t.json "tweaks"
    t.datetime "updated_at", null: false
    t.integer "upload_id", null: false
    t.string "uuid", null: false
    t.index ["created_at"], name: "index_projects_on_created_at"
    t.index ["current_blender_scene_id"], name: "index_projects_on_current_blender_scene_id"
    t.index ["deleted_at"], name: "index_projects_on_deleted_at"
    t.index ["order_id"], name: "index_projects_on_order_id"
    t.index ["upload_id"], name: "index_projects_on_upload_id"
    t.index ["uuid"], name: "index_projects_on_uuid", unique: true
  end

  create_table "refunds", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.integer "order_item_id", null: false
    t.string "stripe_refund_id"
    t.datetime "updated_at", null: false
    t.index ["order_item_id"], name: "index_refunds_on_order_item_id"
  end

  create_table "requests", force: :cascade do |t|
    t.string "action"
    t.string "controller"
    t.datetime "created_at", null: false
    t.json "form_params"
    t.string "ip_address"
    t.string "method"
    t.string "path"
    t.string "referrer"
    t.integer "response_time_ms"
    t.integer "status_code"
    t.datetime "updated_at", null: false
    t.json "url_params"
    t.string "user_agent"
    t.integer "user_id"
    t.string "uuid"
    t.string "visitor_id"
    t.index ["controller", "action"], name: "index_requests_on_controller_and_action"
    t.index ["created_at"], name: "index_requests_on_created_at"
    t.index ["ip_address"], name: "index_requests_on_ip_address"
    t.index ["path", "method"], name: "index_requests_on_path_and_method"
    t.index ["status_code"], name: "index_requests_on_status_code"
    t.index ["user_id"], name: "index_requests_on_user_id"
    t.index ["uuid"], name: "index_requests_on_uuid", unique: true
    t.index ["visitor_id", "created_at"], name: "index_requests_on_visitor_id_and_created_at"
    t.index ["visitor_id"], name: "index_requests_on_visitor_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "upload_zip_checks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "upload_id", null: false
    t.json "zip_contents"
    t.string "zip_filename", null: false
    t.index ["upload_id"], name: "index_upload_zip_checks_on_upload_id"
  end

  create_table "uploads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "guest_email_address"
    t.string "guest_session_id"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "uuid"
    t.index ["user_id"], name: "index_uploads_on_user_id"
    t.index ["uuid"], name: "index_uploads_on_uuid", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "email_address", null: false
    t.boolean "email_address_verified", default: false
    t.string "name"
    t.integer "page_variant_id"
    t.string "password_digest", null: false
    t.integer "render_credit_cents", default: 0
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["page_variant_id"], name: "index_users_on_page_variant_id"
  end

  create_table "workflows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "eta"
    t.string "node_provider_id"
    t.string "node_type_name"
    t.integer "progress_permil"
    t.json "result"
    t.string "status"
    t.json "timing"
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.integer "workflowable_id"
    t.string "workflowable_type"
    t.index ["uuid"], name: "index_workflows_on_uuid", unique: true
    t.index ["workflowable_type", "workflowable_id"], name: "index_workflows_on_workflowable"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "affiliate_monthly_stats", "affiliates"
  add_foreign_key "affiliates", "landing_pages"
  add_foreign_key "affiliates", "users"
  add_foreign_key "articles", "users"
  add_foreign_key "blender_scenes", "projects"
  add_foreign_key "credit_entries", "orders"
  add_foreign_key "credit_entries", "refunds"
  add_foreign_key "credit_entries", "users"
  add_foreign_key "events", "requests"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "projects"
  add_foreign_key "orders", "users"
  add_foreign_key "page_variants", "landing_pages"
  add_foreign_key "project_benchmarks", "projects"
  add_foreign_key "project_blend_checks", "projects"
  add_foreign_key "project_renders", "projects"
  add_foreign_key "projects", "blender_scenes", column: "current_blender_scene_id"
  add_foreign_key "projects", "orders"
  add_foreign_key "projects", "uploads"
  add_foreign_key "refunds", "order_items"
  add_foreign_key "requests", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "upload_zip_checks", "uploads"
  add_foreign_key "uploads", "users"
  add_foreign_key "users", "page_variants"
end
