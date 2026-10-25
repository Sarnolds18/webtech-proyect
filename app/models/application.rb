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

  # The host has not accepted or rejected it yet (same states as the `undecided` scope).
  def undecided?
    pending? || shortlisted?
  end

  # The seeker can take back an application only while the host has not decided on it yet.
  def withdrawable?
    undecided?
  end

  # The transitions below raise ActiveRecord::RecordInvalid (with the reason in `errors`) when they
  # do not apply, so controllers can rescue them like any failed save.

  def withdraw!
    transition_error!(:status, "cannot be withdrawn once it is #{status}") unless withdrawable?

    withdrawn!
  end

  def shortlist!
    transition_error!(:status, "cannot be shortlisted once it is #{status}") unless pending?
    transition_error!(:listing, "is not accepting applications") unless listing.published?

    shortlisted!
  end

  def reject!
    transition_error!(:status, "cannot be rejected once it is #{status}") unless pending? || shortlisted?

    rejected!
  end

  # Accepting is all or nothing: this application becomes accepted, every other pending or shortlisted
  # application of the listing becomes rejected, and the listing becomes reserved. The listing row is
  # locked so two hosts' clicks cannot accept two applicants at once; the partial unique index
  # `index_applications_one_accepted_per_listing` is the last line of defence.
  def accept!
    transaction do
      listing.lock!
      transition_error!(:status, "cannot be accepted once it is #{status}") unless pending? || shortlisted?
      transition_error!(:listing, "is not accepting applications") unless listing.published?

      accepted!
      listing.applications.undecided.where.not(id: id).update_all(status: "rejected", updated_at: Time.current)
      listing.reserved!
    end
  end

  private

  def transition_error!(attribute, message)
    errors.add(attribute, message)
    raise ActiveRecord::RecordInvalid, self
  end

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
