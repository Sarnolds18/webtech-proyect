class Visit < ApplicationRecord
  belongs_to :application
  has_one :review, dependent: :destroy
  has_one :listing, through: :application

  enum :status, {
    proposed: "proposed",
    confirmed: "confirmed",
    completed: "completed",
    cancelled: "cancelled"
  }, default: :proposed

  validates :scheduled_at, presence: true
  # Only when the date changes, so past visits stay valid when their status is updated.
  validate :scheduled_after_application, if: :scheduled_at_changed?
  validate :scheduled_in_the_future, if: :scheduled_at_changed?
  # The host proposes visits only to the applicants on the shortlist.
  validate :application_must_be_shortlisted, on: :create

  scope :upcoming, -> { where(scheduled_at: Time.current..) }
  scope :past, -> { where(scheduled_at: ...Time.current) }
  scope :chronological, -> { order(:scheduled_at) }

  def host
    application.listing.host
  end

  def seeker
    application.seeker
  end

  # Lifecycle: proposed -> confirmed (by the seeker) -> completed, or cancelled while it is proposed
  # or confirmed. Each transition raises ActiveRecord::RecordInvalid, with the reason in `errors`,
  # when the visit is not in a state that allows it.
  def confirmable?
    proposed?
  end

  def cancellable?
    proposed? || confirmed?
  end

  def completable?
    confirmed?
  end

  def confirm!
    transition_to!(:confirmed, allowed: confirmable?, otherwise: "can only be confirmed while it is proposed")
  end

  def cancel!
    transition_to!(:cancelled, allowed: cancellable?, otherwise: "cannot be cancelled once it is #{status}")
  end

  def complete!
    transition_to!(:completed, allowed: completable?, otherwise: "can only be completed once it is confirmed")
  end

  # Rescheduling keeps the history: this visit is cancelled and a new proposed one is created at the new
  # time, both or neither. Returns the new visit. When the new time is not valid, its errors are copied
  # here so the controller handles every failure the same way.
  def reschedule!(new_time)
    transaction do
      cancel!
      application.visits.create!(scheduled_at: new_time)
    end
  rescue ActiveRecord::RecordInvalid => error
    raise if error.record == self

    error.record.errors.each { |new_visit_error| errors.import(new_visit_error) }
    raise ActiveRecord::RecordInvalid, self
  end

  private

  def transition_to!(new_status, allowed:, otherwise:)
    unless allowed
      errors.add(:status, otherwise)
      raise ActiveRecord::RecordInvalid, self
    end

    update!(status: new_status)
  end

  def scheduled_after_application
    return if scheduled_at.blank? || application&.created_at.blank?

    if scheduled_at <= application.created_at
      errors.add(:scheduled_at, "must be after the application was created")
    end
  end

  def scheduled_in_the_future
    return if scheduled_at.blank?

    errors.add(:scheduled_at, "must be in the future") if scheduled_at <= Time.current
  end

  def application_must_be_shortlisted
    return if application.nil? || application.shortlisted?

    errors.add(:application, "must be shortlisted before a visit is proposed")
  end
end
