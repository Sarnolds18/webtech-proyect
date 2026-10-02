class CreateReviewReplies < ActiveRecord::Migration[8.1]
  def change
    create_table :review_replies do |t|
      t.references :review, null: false, foreign_key: true, index: { unique: true }
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.text :comment, null: false

      t.timestamps
    end
  end
end
