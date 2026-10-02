class Property < ApplicationRecord
  belongs_to :host, class_name: "User"
  belongs_to :neighborhood

  has_many :property_amenities, dependent: :destroy
  has_many :amenities, through: :property_amenities

  enum :property_type, { apartment: "apartment", house: "house", studio: "studio" }

  validates :title, :address, presence: true
  validates :bedrooms, :bathrooms, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
end
