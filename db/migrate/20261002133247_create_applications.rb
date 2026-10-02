class CreateApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :applications do |t|
      t.references :listing, null: false, foreign_key: true
      t.references :seeker, null: false, foreign_key: { to_table: :users }
      t.text :message, null: false
      t.date :move_in_date, null: false
      t.integer :stay_months, null: false
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :applications, %i[listing_id seeker_id], unique: true
    add_index :applications, :status
    # A listing can never have two accepted applications.
    add_index :applications, :listing_id, unique: true, where: "status = 'accepted'",
                                          name: "index_applications_one_accepted_per_listing"

    add_check_constraint :applications, "stay_months >= 1", name: "applications_stay_positive"
    add_check_constraint :applications,
                         "status::text IN ('pending', 'shortlisted', 'accepted', 'rejected', 'withdrawn')",
                         name: "applications_status_valid"
  end
end
