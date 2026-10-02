class CreateNeighborhoods < ActiveRecord::Migration[8.1]
  def change
    create_table :neighborhoods do |t|
      t.string :name, null: false
      t.string :city, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :neighborhoods, %i[name city], unique: true
  end
end
