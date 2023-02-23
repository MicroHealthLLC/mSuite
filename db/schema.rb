# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_02_23_055034) do

  create_table "active_admin_comments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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

  create_table "active_storage_attachments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "categories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "comments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "message"
    t.string "feedback"
    t.boolean "status"
    t.integer "mindmap_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parent_comment"
    t.string "user_name"
  end

  create_table "mindmap_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "mindmap_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mindmaps", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
    t.text "canvas", limit: 4294967295
    t.integer "is_save"
    t.integer "parent_id"
    t.integer "failed_password_attempts"
    t.integer "total_failed_password_attempts"
    t.datetime "lockout_period"
    t.boolean "permanent_lock", default: false
    t.index ["unique_key"], name: "index_mindmaps_on_unique_key", unique: true
  end

  create_table "nodes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
    t.index ["mindmap_id"], name: "index_nodes_on_mindmap_id"
  end

  create_table "settings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
    t.integer "failed_password_attempts"
    t.integer "lockout_period"
    t.integer "permanent_lock"
  end

  create_table "stages", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "title"
    t.integer "mindmap_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", default: 0
    t.string "stage_color", default: "#ebecf0"
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
  add_foreign_key "nodes", "mindmaps"
end
