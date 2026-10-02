class Neighborhood < ApplicationRecord
  validates :name, presence: true, uniqueness: { scope: :city }
  validates :city, presence: true

  scope :active, -> { where(active: true) }
  scope :alphabetical, -> { order(:name) }
end
