class SavedListing < ApplicationRecord
  belongs_to :user
  belongs_to :listing

  validates :listing_id, uniqueness: { scope: :user_id, message: "is already saved" }
end
