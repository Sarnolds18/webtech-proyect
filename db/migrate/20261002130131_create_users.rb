class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :phone
      t.text :bio
      t.string :role, null: false, default: "member"
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :users, :email_address, unique: true
    add_check_constraint :users, "role IN ('member', 'moderator')", name: "users_role_valid"
    add_check_constraint :users, "status IN ('active', 'suspended')", name: "users_status_valid"
  end
end
