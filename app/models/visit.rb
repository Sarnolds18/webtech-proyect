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

  scope :upcoming, -> { where(scheduled_at: Time.current..) }
  scope :past, -> { where(scheduled_at: ...Time.current) }
  scope :chronological, -> { order(:scheduled_at) }

  private

  def scheduled_after_application
    return if scheduled_at.blank? || application&.created_at.blank?

    if scheduled_at <= application.created_at
      errors.add(:scheduled_at, "must be after the application was created")
    end
  end
end
