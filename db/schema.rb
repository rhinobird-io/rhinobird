# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150203040157) do

  create_table "appointments", force: :cascade do |t|
    t.integer "event_id"
    t.integer "participant_id"
  end

  add_index "appointments", ["event_id"], name: "index_appointments_on_event_id"
  add_index "appointments", ["participant_id"], name: "index_appointments_on_participant_id"

  create_table "dashboard_records", force: :cascade do |t|
    t.integer  "user_id"
    t.text     "content",      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "from_user_id"
  end

  add_index "dashboard_records", ["user_id"], name: "index_dashboard_records_on_user_id"

  create_table "events", force: :cascade do |t|
    t.string   "title"
    t.boolean  "full_day"
    t.boolean  "period"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "creator_id"
    t.datetime "fromTime"
    t.datetime "toTime"
  end

  add_index "events", ["creator_id"], name: "index_events_on_creator_id"

  create_table "invitations", force: :cascade do |t|
    t.string   "email"
    t.integer  "from_user_id"
    t.integer  "initial_team_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "local_avatars", force: :cascade do |t|
    t.integer  "user_id"
    t.binary   "image_data", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "local_avatars", ["user_id"], name: "index_local_avatars_on_user_id"

  create_table "notifications", force: :cascade do |t|
    t.integer  "user_id"
    t.text     "content",                      null: false
    t.integer  "from_user_id",                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "checked",      default: false
  end

  add_index "notifications", ["user_id"], name: "index_notifications_on_user_id"

  create_table "plugins", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "author"
    t.string   "url"
  end

  add_index "plugins", ["name"], name: "index_plugins_on_name", unique: true

  create_table "teams", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "realname"
    t.string   "email"
    t.string   "encrypted_password"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users_teams", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.integer  "team_id",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users_teams", ["user_id"], name: "index_users_teams_on_user_id"

end
