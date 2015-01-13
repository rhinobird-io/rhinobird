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

ActiveRecord::Schema.define(version: 20150109100541) do

  create_table "dashboard_records", force: true do |t|
    t.integer  "user_id"
    t.text     "content",      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "from_user_id"
  end

  add_index "dashboard_records", ["user_id"], name: "index_dashboard_records_on_user_id"

  create_table "plugins", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "author"
    t.string   "url"
  end

  add_index "plugins", ["name"], name: "index_plugins_on_name", unique: true

  create_table "questions", force: true do |t|
    t.integer "vote_id"
    t.text    "description"
    t.text    "options"
  end

  create_table "teams", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "name"
    t.string   "realname"
    t.string   "email"
    t.string   "encrypted_password"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["name"], name: "index_users_on_name", unique: true

  create_table "users_teams", force: true do |t|
    t.integer  "user_id",    null: false
    t.integer  "team_id",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users_teams", ["user_id"], name: "index_users_teams_on_user_id"

  create_table "vote_statuses", force: true do |t|
    t.integer  "vote_id"
    t.string   "user"
    t.boolean  "finished"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vote_statuses", ["vote_id"], name: "index_vote_statuses_on_vote_id"

  create_table "votes", force: true do |t|
    t.text     "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
