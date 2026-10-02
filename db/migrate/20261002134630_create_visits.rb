class CreateVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :visits do |t|
      t.references :application, null: false, foreign_key: true
      t.datetime :scheduled_at, null: false
      t.string :status, null: false, default: "proposed"

      t.timestamps
    end

    add_check_constraint :visits,
                         "status::text IN ('proposed', 'confirmed', 'completed', 'cancelled')",
                         name: "visits_status_valid"
  end
end
