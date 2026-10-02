class Neighborhood < ApplicationRecord
  has_many :properties, dependent: :restrict_with_error
  has_many :listings, through: :properties

  validates :name, presence: true, uniqueness: { scope: :city }
  validates :city, presence: true

  scope :active, -> { where(active: true) }
  scope :alphabetical, -> { order(:name) }
end
