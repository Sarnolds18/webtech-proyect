class CreateReports < ActiveRecord::Migration[8.1]
  def change
    create_table :reports do |t|
      t.references :listing, null: false, foreign_key: true
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.string :reason, null: false
      t.text :details
      t.string :status, null: false, default: "open"

      t.timestamps
    end

    add_index :reports, %i[listing_id reporter_id], unique: true
    add_index :reports, :status

    add_check_constraint :reports, "reason::text IN ('fraudulent', 'misleading', 'offensive')",
                         name: "reports_reason_valid"
    add_check_constraint :reports, "status::text IN ('open', 'dismissed', 'action_taken')",
                         name: "reports_status_valid"
  end
end
