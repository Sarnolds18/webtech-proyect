class Property < ApplicationRecord
  belongs_to :host, class_name: "User"
  belongs_to :neighborhood

  has_many :property_amenities, dependent: :destroy
  has_many :amenities, through: :property_amenities
  has_many :listings, dependent: :restrict_with_error
  has_many :reviews, dependent: :destroy

  enum :property_type, { apartment: "apartment", house: "house", studio: "studio" }

  validates :title, :address, presence: true
  validates :bedrooms, :bathrooms, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  def average_rating
    # Float, not BigDecimal: BigDecimal#to_s prints "0.45e1" in views.
    reviews.average(:rating)&.to_f&.round(1)
  end
end
