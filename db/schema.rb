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

ActiveRecord::Schema[8.1].define(version: 2026_10_02_135434) do
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

  create_table "applications", force: :cascade do |t|
    t.bigint "listing_id", null: false
    t.bigint "seeker_id", null: false
    t.text "message", null: false
    t.date "move_in_date", null: false
    t.integer "stay_months", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id", "seeker_id"], name: "index_applications_on_listing_id_and_seeker_id", unique: true
    t.index ["listing_id"], name: "index_applications_on_listing_id"
    t.index ["listing_id"], name: "index_applications_one_accepted_per_listing", unique: true, where: "((status)::text = 'accepted'::text)"
    t.index ["seeker_id"], name: "index_applications_on_seeker_id"
    t.index ["status"], name: "index_applications_on_status"
    t.check_constraint "status::text = ANY (ARRAY['pending'::text, 'shortlisted'::text, 'accepted'::text, 'rejected'::text, 'withdrawn'::text])", name: "applications_status_valid"
    t.check_constraint "stay_months >= 1", name: "applications_stay_positive"
  end

  create_table "listings", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.string "title", null: false
    t.text "description"
    t.text "house_rules"
    t.integer "monthly_rent", null: false
    t.integer "deposit", default: 0, null: false
    t.date "available_from", null: false
    t.integer "minimum_stay_months", default: 1, null: false
    t.boolean "furnished", default: false, null: false
    t.boolean "private_bathroom", default: false, null: false
    t.string "status", default: "draft", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["available_from"], name: "index_listings_on_available_from"
    t.index ["monthly_rent"], name: "index_listings_on_monthly_rent"
    t.index ["property_id"], name: "index_listings_on_property_id"
    t.index ["status"], name: "index_listings_on_status"
    t.check_constraint "deposit >= 0", name: "listings_deposit_not_negative"
    t.check_constraint "minimum_stay_months >= 1", name: "listings_minimum_stay_positive"
    t.check_constraint "monthly_rent > 0", name: "listings_rent_positive"
    t.check_constraint "status::text = ANY (ARRAY['draft'::text, 'published'::text, 'reserved'::text, 'rented'::text, 'withdrawn'::text])", name: "listings_status_valid"
  end

  create_table "moderation_actions", force: :cascade do |t|
    t.bigint "moderator_id", null: false
    t.bigint "report_id"
    t.bigint "target_listing_id"
    t.bigint "target_user_id"
    t.string "action_type", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["moderator_id"], name: "index_moderation_actions_on_moderator_id"
    t.index ["report_id"], name: "index_moderation_actions_on_report_id"
    t.index ["target_listing_id"], name: "index_moderation_actions_on_target_listing_id"
    t.index ["target_user_id"], name: "index_moderation_actions_on_target_user_id"
    t.check_constraint "action_type::text = ANY (ARRAY['dismiss_report'::text, 'withdraw_listing'::text, 'remove_review'::text, 'suspend_user'::text])", name: "moderation_actions_type_valid"
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
    t.check_constraint "property_type::text = ANY (ARRAY['apartment'::text, 'house'::text, 'studio'::text])", name: "properties_type_valid"
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

  create_table "reports", force: :cascade do |t|
    t.bigint "listing_id", null: false
    t.bigint "reporter_id", null: false
    t.string "reason", null: false
    t.text "details"
    t.string "status", default: "open", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id", "reporter_id"], name: "index_reports_on_listing_id_and_reporter_id", unique: true
    t.index ["listing_id"], name: "index_reports_on_listing_id"
    t.index ["reporter_id"], name: "index_reports_on_reporter_id"
    t.index ["status"], name: "index_reports_on_status"
    t.check_constraint "reason::text = ANY (ARRAY['fraudulent'::text, 'misleading'::text, 'offensive'::text])", name: "reports_reason_valid"
    t.check_constraint "status::text = ANY (ARRAY['open'::text, 'dismissed'::text, 'action_taken'::text])", name: "reports_status_valid"
  end

  create_table "review_replies", force: :cascade do |t|
    t.bigint "review_id", null: false
    t.bigint "author_id", null: false
    t.text "comment", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_review_replies_on_author_id"
    t.index ["review_id"], name: "index_review_replies_on_review_id", unique: true
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "visit_id", null: false
    t.bigint "property_id", null: false
    t.bigint "author_id", null: false
    t.integer "rating", null: false
    t.text "comment", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_reviews_on_author_id"
    t.index ["property_id"], name: "index_reviews_on_property_id"
    t.index ["visit_id"], name: "index_reviews_on_visit_id", unique: true
    t.check_constraint "rating >= 1 AND rating <= 5", name: "reviews_rating_range"
  end

  create_table "saved_listings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "listing_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id"], name: "index_saved_listings_on_listing_id"
    t.index ["user_id", "listing_id"], name: "index_saved_listings_on_user_id_and_listing_id", unique: true
    t.index ["user_id"], name: "index_saved_listings_on_user_id"
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
    t.check_constraint "role::text = ANY (ARRAY['member'::text, 'moderator'::text])", name: "users_role_valid"
    t.check_constraint "status::text = ANY (ARRAY['active'::text, 'suspended'::text])", name: "users_status_valid"
  end

  create_table "visits", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.datetime "scheduled_at", null: false
    t.string "status", default: "proposed", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_visits_on_application_id"
    t.check_constraint "status::text = ANY (ARRAY['proposed'::text, 'confirmed'::text, 'completed'::text, 'cancelled'::text])", name: "visits_status_valid"
  end

  add_foreign_key "applications", "listings"
  add_foreign_key "applications", "users", column: "seeker_id"
  add_foreign_key "listings", "properties"
  add_foreign_key "moderation_actions", "listings", column: "target_listing_id"
  add_foreign_key "moderation_actions", "reports"
  add_foreign_key "moderation_actions", "users", column: "moderator_id"
  add_foreign_key "moderation_actions", "users", column: "target_user_id"
  add_foreign_key "properties", "neighborhoods"
  add_foreign_key "properties", "users", column: "host_id"
  add_foreign_key "property_amenities", "amenities"
  add_foreign_key "property_amenities", "properties"
  add_foreign_key "reports", "listings"
  add_foreign_key "reports", "users", column: "reporter_id"
  add_foreign_key "review_replies", "reviews"
  add_foreign_key "review_replies", "users", column: "author_id"
  add_foreign_key "reviews", "properties"
  add_foreign_key "reviews", "users", column: "author_id"
  add_foreign_key "reviews", "visits"
  add_foreign_key "saved_listings", "listings"
  add_foreign_key "saved_listings", "users"
  add_foreign_key "visits", "applications"
end
