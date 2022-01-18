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

ActiveRecord::Schema.define(version: 2021_09_05_101234) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "caches", force: :cascade do |t|
    t.string "type", null: false
    t.string "value"
    t.integer "caches_domains_count", default: 0, null: false
    t.datetime "last_updated_at", precision: 6, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index "digest((value)::text, 'sha1'::text), type", name: "index_caches_on_digest_value_sha1_text_type", unique: true
    t.index ["type", "id"], name: "index_caches_on_type_and_id"
    t.index ["type"], name: "index_caches_on_type"
  end

  create_table "caches_domains", force: :cascade do |t|
    t.bigint "cache_id", null: false
    t.bigint "domain_id", null: false
    t.datetime "last_updated_at", precision: 6, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["cache_id", "domain_id"], name: "index_caches_domains_on_cache_id_and_domain_id", unique: true
    t.index ["cache_id"], name: "index_caches_domains_on_cache_id"
    t.index ["domain_id"], name: "index_caches_domains_on_domain_id"
  end

  create_table "clients", force: :cascade do |t|
    t.cidr "ip_address", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["ip_address"], name: "index_clients_on_ip_address", unique: true
  end

  create_table "domains", force: :cascade do |t|
    t.string "type", null: false
    t.string "value"
    t.integer "caches_domains_count", default: 0, null: false
    t.datetime "last_updated_at", precision: 6, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "owner_type"
    t.bigint "owner_id"
    t.index "digest((value)::text, 'sha1'::text), owner_type, owner_id", name: "index_domains_on_digest_value_sha1_text_owner_type_owner_id", unique: true
    t.index ["owner_type", "owner_id"], name: "index_domains_on_owner"
    t.index ["type", "id"], name: "index_domains_on_type_and_id"
    t.index ["type"], name: "index_domains_on_type"
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id"
    t.text "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri"
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "caches_domains", "caches", column: "cache_id"
  add_foreign_key "caches_domains", "domains"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
end
