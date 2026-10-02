class Application < ApplicationRecord
  belongs_to :listing
  belongs_to :seeker, class_name: "User"
  has_many :visits, dependent: :destroy

  enum :status, {
    pending: "pending",
    shortlisted: "shortlisted",
    accepted: "accepted",
    rejected: "rejected",
    withdrawn: "withdrawn"
  }, default: :pending

  validates :message, :move_in_date, presence: true
  validates :stay_months, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :seeker_id, uniqueness: { scope: :listing_id, message: "has already applied to this listing" }
  validate :seeker_is_not_the_host

  # Applications the host has not answered yet (same as `pending`, named for the inbox).
  scope :awaiting_answer, -> { where(status: :pending) }
  # Applications still in play: the host can still accept or reject them.
  scope :undecided, -> { where(status: %i[pending shortlisted]) }
  scope :for_listing, ->(listing) { where(listing: listing) }
  scope :recent_first, -> { order(created_at: :desc) }

  private

  def seeker_is_not_the_host
    return if listing.nil? || seeker.nil?

    errors.add(:seeker, "cannot apply to their own listing") if listing.host == seeker
  end
end
