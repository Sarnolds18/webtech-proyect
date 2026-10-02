class CreateAmenities < ActiveRecord::Migration[8.1]
  def change
    create_table :amenities do |t|
      t.string :name, null: false
      t.string :icon
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :amenities, :name, unique: true
  end
end
