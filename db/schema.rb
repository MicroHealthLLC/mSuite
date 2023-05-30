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

ActiveRecord::Schema.define(version: 2023_05_25_210947) do

  create_table "active_admin_comments", charset: "utf8", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "active_storage_attachments", charset: "utf8", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "categories", charset: "utf8", force: :cascade do |t|
    t.string "name"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "comments", charset: "utf8", force: :cascade do |t|
    t.string "message"
    t.string "feedback"
    t.boolean "status"
    t.integer "mindmap_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parent_comment"
    t.string "user_name"
  end

  create_table "mindmap_users", charset: "utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "mindmap_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mindmaps", charset: "utf8", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "unique_key"
    t.text "description"
    t.bigint "user_id"
    t.integer "status", default: 0
    t.bigint "category_id"
    t.integer "share", default: 0
    t.datetime "expires_at"
    t.integer "mm_type", default: 0, null: false
    t.string "password"
    t.string "line_color", default: "#B3FAFF"
    t.binary "image"
    t.string "title", default: "Title"
    t.date "will_delete_at"
    t.text "canvas", size: :long
    t.integer "is_save"
    t.integer "parent_id"
    t.integer "failed_password_attempts"
    t.integer "total_failed_password_attempts"
    t.datetime "lockout_period"
    t.boolean "permanent_lock", default: false
    t.index ["unique_key"], name: "index_mindmaps_on_unique_key", unique: true
  end

  create_table "nodes", charset: "utf8", force: :cascade do |t|
    t.string "title"
    t.float "position_x"
    t.float "position_y"
    t.integer "parent_node"
    t.bigint "mindmap_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_disabled", default: false
    t.boolean "hide_children", default: false
    t.boolean "hide_self", default: false
    t.string "line_color"
    t.text "description"
    t.integer "export_index"
    t.integer "stage_id"
    t.integer "position", default: 0
    t.integer "node_width", default: 0
    t.datetime "duedate"
    t.datetime "startdate"
    t.string "element_type"
    t.float "element_width"
    t.float "element_height"
    t.boolean "is_sprint", default: false
    t.index ["mindmap_id"], name: "index_nodes_on_mindmap_id"
  end

  create_table "settings", charset: "utf8", force: :cascade do |t|
    t.text "office365_key"
    t.text "office365_secret"
    t.text "google_oauth_key"
    t.text "google_oauth_secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "google_recaptcha_site_key"
    t.text "host_url"
    t.boolean "beta_status"
    t.string "beta_url"
    t.string "public_url"
    t.string "about_url"
    t.string "terms_url"
    t.string "privacy_url"
    t.integer "failed_password_attempts", default: 0, null: false
    t.integer "lockout_period", default: 1, null: false
    t.integer "permanent_lock", default: 5, null: false
  end

  create_table "stages", charset: "utf8", force: :cascade do |t|
    t.string "title"
    t.integer "mindmap_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", default: 0
    t.string "stage_color", default: "#ebecf0"
  end

  create_table "users", charset: "utf8", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "first_name"
    t.string "last_name"
    t.integer "role", default: 0
    t.string "provider"
    t.string "uid"
    t.string "login"
    t.integer "status", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "nodes", "mindmaps"
end
