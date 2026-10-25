class Amenity < ApplicationRecord
  has_many :property_amenities, dependent: :destroy
  has_many :properties, through: :property_amenities

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  # A Bootstrap Icons class such as "bi-wifi"; it is printed inside a class attribute.
  validates :icon, format: { with: /\Abi-[a-z0-9-]+\z/, message: "must be a Bootstrap Icons class, e.g. bi-wifi" },
                   allow_blank: true

  scope :active, -> { where(active: true) }
  scope :alphabetical, -> { order(:name) }
end
