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

ActiveRecord::Schema[8.0].define(version: 2026_03_29_151334) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "full_name"
    t.string "uid"
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
  end

  create_table "attendance_records", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.date "date"
    t.boolean "is_present"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_attendance_records_on_member_id"
  end

  create_table "attendances", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.date "date", null: false
    t.boolean "attended", default: false, null: false
    t.integer "source", default: 0, null: false
    t.string "external_id"
    t.text "notes"
    t.boolean "override_by_leadership", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "days_attended", default: 0, null: false
    t.index ["external_id"], name: "index_attendances_on_external_id"
    t.index ["player_id", "date"], name: "index_attendances_on_player_id_and_date", unique: true
    t.index ["player_id"], name: "index_attendances_on_player_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.integer "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "recsports_credentials", force: :cascade do |t|
    t.integer "access_mode", default: 0, null: false
    t.string "form_url", null: false
    t.string "username"
    t.string "password"
    t.boolean "active", default: true, null: false
    t.datetime "last_checked_at"
    t.text "last_error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "browser_sync_token"
    t.index ["browser_sync_token"], name: "index_recsports_credentials_on_browser_sync_token", unique: true
  end

  create_table "recsports_event_participants", force: :cascade do |t|
    t.bigint "recsports_event_id", null: false
    t.bigint "user_id", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "recsports_uin"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recsports_event_id", "recsports_uin"], name: "index_recsports_participants_on_event_and_uin"
    t.index ["recsports_event_id", "user_id"], name: "index_recsports_participants_on_event_and_user", unique: true
    t.index ["recsports_event_id"], name: "index_recsports_event_participants_on_recsports_event_id"
    t.index ["user_id"], name: "index_recsports_event_participants_on_user_id"
  end

  create_table "recsports_events", force: :cascade do |t|
    t.string "title", null: false
    t.string "event_type"
    t.string "venue"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.string "source_url", null: false
    t.string "external_id"
    t.string "created_by_name"
    t.string "created_by_email"
    t.datetime "source_created_at"
    t.datetime "synced_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_recsports_events_on_external_id"
    t.index ["source_url"], name: "index_recsports_events_on_source_url", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.integer "role", default: 0, null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uid"
    t.string "avatar_url"
    t.string "recsports_uin"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["recsports_uin"], name: "index_users_on_recsports_uin", unique: true
  end

  create_table "weekly_workouts", force: :cascade do |t|
    t.date "week_start_date"
    t.boolean "complete"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "player_id", null: false
    t.index ["player_id", "week_start_date"], name: "index_weekly_workouts_on_player_id_and_week_start_date", unique: true
    t.index ["player_id"], name: "index_weekly_workouts_on_player_id"
  end

  create_table "workout_checkins", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.date "workout_date", null: false
    t.string "proof_url"
    t.integer "source", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id", "workout_date"], name: "index_workout_checkins_on_player_id_and_workout_date", unique: true
    t.index ["player_id"], name: "index_workout_checkins_on_player_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attendance_records", "members"
  add_foreign_key "attendances", "users", column: "player_id"
  add_foreign_key "recsports_event_participants", "recsports_events"
  add_foreign_key "recsports_event_participants", "users"
  add_foreign_key "weekly_workouts", "users", column: "player_id"
  add_foreign_key "workout_checkins", "users", column: "player_id"
end
