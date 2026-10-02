class CreateModerationActions < ActiveRecord::Migration[8.1]
  def change
    create_table :moderation_actions do |t|
      t.references :moderator, null: false, foreign_key: { to_table: :users }
      t.references :report, foreign_key: true
      t.references :target_listing, foreign_key: { to_table: :listings }
      t.references :target_user, foreign_key: { to_table: :users }
      t.string :action_type, null: false
      t.text :notes

      t.timestamps
    end

    add_check_constraint :moderation_actions,
                         "action_type::text IN ('dismiss_report', 'withdraw_listing', 'remove_review', 'suspend_user')",
                         name: "moderation_actions_type_valid"
  end
end
