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

ActiveRecord::Schema[8.0].define(version: 2026_02_15_222534) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
    t.decimal "hours", precision: 6, scale: 2, default: "0.0", null: false
    t.boolean "attended", default: false, null: false
    t.integer "source", default: 0, null: false
    t.string "external_id"
    t.text "notes"
    t.boolean "override_by_leadership", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.integer "role", default: 0, null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "coach", default: false
    t.string "uid"
    t.string "avatar_url"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "weekly_workouts", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.date "week_start_date"
    t.boolean "complete"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_weekly_workouts_on_member_id"
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

  add_foreign_key "attendance_records", "members"
  add_foreign_key "attendances", "users", column: "player_id"
  add_foreign_key "weekly_workouts", "members"
  add_foreign_key "workout_checkins", "users", column: "player_id"
end
