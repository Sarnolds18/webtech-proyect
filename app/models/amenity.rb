class Amenity < ApplicationRecord
  has_many :property_amenities, dependent: :destroy
  has_many :properties, through: :property_amenities

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :active, -> { where(active: true) }
  scope :alphabetical, -> { order(:name) }
end
