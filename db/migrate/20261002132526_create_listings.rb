class CreateListings < ActiveRecord::Migration[8.1]
  def change
    create_table :listings do |t|
      t.references :property, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.text :house_rules
      t.integer :monthly_rent, null: false
      t.integer :deposit, null: false, default: 0
      t.date :available_from, null: false
      t.integer :minimum_stay_months, null: false, default: 1
      t.boolean :furnished, null: false, default: false
      t.boolean :private_bathroom, null: false, default: false
      t.string :status, null: false, default: "draft"

      t.timestamps
    end

    add_index :listings, :status
    add_index :listings, :available_from
    add_index :listings, :monthly_rent

    add_check_constraint :listings, "monthly_rent > 0", name: "listings_rent_positive"
    add_check_constraint :listings, "deposit >= 0", name: "listings_deposit_not_negative"
    add_check_constraint :listings, "minimum_stay_months >= 1", name: "listings_minimum_stay_positive"
    add_check_constraint :listings,
                         "status IN ('draft', 'published', 'reserved', 'rented', 'withdrawn')",
                         name: "listings_status_valid"
  end
end
