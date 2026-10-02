class Listing < ApplicationRecord
  belongs_to :property
  has_one :neighborhood, through: :property
  has_many :applications, dependent: :destroy
  has_many :seekers, through: :applications

  enum :status, {
    draft: "draft",
    published: "published",
    reserved: "reserved",
    rented: "rented",
    withdrawn: "withdrawn"
  }, default: :draft

  validates :title, presence: true
  validates :monthly_rent, numericality: { only_integer: true, greater_than: 0 }
  validates :deposit, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :minimum_stay_months, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :available_from, presence: true
  # Only on create, so historical listings (e.g. already rented) stay valid when edited later.
  validate :available_from_not_in_past, on: :create

  # Filter scopes are chainable and return everything when the argument is blank,
  # because they are fed straight from form params (which arrive as strings).

  # Rooms that are available on or before the given date, i.e. `available_from <= date`.
  scope :available_by, ->(date) { date.present? ? where(available_from: ..date) : all }
  scope :under_rent, ->(amount) { amount.present? ? where(monthly_rent: ..amount.to_i) : all }
  scope :in_neighborhood, ->(id) { id.present? ? joins(:property).where(properties: { neighborhood_id: id }) : all }
  scope :furnished_only, -> { where(furnished: true) }
  scope :with_private_bathroom, -> { where(private_bathroom: true) }
  scope :cheapest_first, -> { order(:monthly_rent) }
  scope :soonest_available, -> { order(:available_from) }

  def host
    property.host
  end

  private

  def available_from_not_in_past
    return if available_from.blank?

    errors.add(:available_from, "cannot be in the past") if available_from < Date.current
  end
end
