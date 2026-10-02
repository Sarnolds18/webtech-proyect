class CreateProperties < ActiveRecord::Migration[8.1]
  def change
    create_table :properties do |t|
      t.references :host, null: false, foreign_key: { to_table: :users }
      t.references :neighborhood, null: false, foreign_key: true
      t.string :title, null: false
      t.string :address, null: false
      t.string :property_type, null: false
      t.integer :bedrooms, null: false
      t.integer :bathrooms, null: false
      t.text :shared_spaces
      t.text :description

      t.timestamps
    end

    add_check_constraint :properties, "bedrooms >= 1", name: "properties_bedrooms_positive"
    add_check_constraint :properties, "bathrooms >= 1", name: "properties_bathrooms_positive"
    add_check_constraint :properties, "property_type IN ('apartment', 'house', 'studio')", name: "properties_type_valid"
  end
end
