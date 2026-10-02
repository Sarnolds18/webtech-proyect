class Neighborhood < ApplicationRecord
  has_many :properties, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :city }
  validates :city, presence: true

  scope :active, -> { where(active: true) }
  scope :alphabetical, -> { order(:name) }
end
