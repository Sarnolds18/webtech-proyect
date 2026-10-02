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

ActiveRecord::Schema[8.1].define(version: 2026_10_02_131524) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "amenities", force: :cascade do |t|
    t.string "name", null: false
    t.string "icon"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_amenities_on_name", unique: true
  end

  create_table "neighborhoods", force: :cascade do |t|
    t.string "name", null: false
    t.string "city", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "city"], name: "index_neighborhoods_on_name_and_city", unique: true
  end

  create_table "properties", force: :cascade do |t|
    t.bigint "host_id", null: false
    t.bigint "neighborhood_id", null: false
    t.string "title", null: false
    t.string "address", null: false
    t.string "property_type", null: false
    t.integer "bedrooms", null: false
    t.integer "bathrooms", null: false
    t.text "shared_spaces"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["host_id"], name: "index_properties_on_host_id"
    t.index ["neighborhood_id"], name: "index_properties_on_neighborhood_id"
    t.check_constraint "bathrooms >= 1", name: "properties_bathrooms_positive"
    t.check_constraint "bedrooms >= 1", name: "properties_bedrooms_positive"
    t.check_constraint "property_type::text = ANY (ARRAY['apartment'::character varying, 'house'::character varying, 'studio'::character varying]::text[])", name: "properties_type_valid"
  end

  create_table "property_amenities", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.bigint "amenity_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["amenity_id"], name: "index_property_amenities_on_amenity_id"
    t.index ["property_id", "amenity_id"], name: "index_property_amenities_on_property_id_and_amenity_id", unique: true
    t.index ["property_id"], name: "index_property_amenities_on_property_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "phone"
    t.text "bio"
    t.string "role", default: "member", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.check_constraint "role::text = ANY (ARRAY['member'::character varying, 'moderator'::character varying]::text[])", name: "users_role_valid"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying, 'suspended'::character varying]::text[])", name: "users_status_valid"
  end

  add_foreign_key "properties", "neighborhoods"
  add_foreign_key "properties", "users", column: "host_id"
  add_foreign_key "property_amenities", "amenities"
  add_foreign_key "property_amenities", "properties"
end
