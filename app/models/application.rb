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
  validate :listing_must_be_published, on: :create

  # Applications the host has not answered yet (same as `pending`, named for the inbox).
  scope :awaiting_answer, -> { where(status: :pending) }
  # Applications still in play: the host can still accept or reject them.
  scope :undecided, -> { where(status: %i[pending shortlisted]) }
  scope :for_listing, ->(listing) { where(listing: listing) }
  scope :recent_first, -> { order(created_at: :desc) }

  # The seeker can take back an application only while the host has not decided on it yet.
  def withdrawable?
    pending? || shortlisted?
  end

  # Raises ActiveRecord::RecordInvalid (with the reason in `errors`) when the application is already
  # accepted, rejected or withdrawn.
  def withdraw!
    unless withdrawable?
      errors.add(:status, "cannot be withdrawn once it is #{status}")
      raise ActiveRecord::RecordInvalid, self
    end

    withdrawn!
  end

  private

  def seeker_is_not_the_host
    return if listing.nil? || seeker.nil?

    errors.add(:seeker, "cannot apply to their own listing") if listing.host == seeker
  end

  # Draft, reserved, rented and withdrawn listings do not take new applications.
  def listing_must_be_published
    return if listing.nil? || listing.published?

    errors.add(:listing, "is not accepting applications")
  end
end
