class Report < ApplicationRecord
  belongs_to :listing
  belongs_to :reporter, class_name: "User"
  has_many :moderation_actions, dependent: :nullify

  enum :reason, { fraudulent: "fraudulent", misleading: "misleading", offensive: "offensive" }
  enum :status, { open: "open", dismissed: "dismissed", action_taken: "action_taken" }, default: :open

  validates :reason, presence: true
  validates :reporter_id, uniqueness: { scope: :listing_id, message: "has already reported this listing" }
  validate :reporter_is_not_the_host

  # Reports a moderator still has to review.
  scope :unresolved, -> { where(status: :open) }
  scope :recent_first, -> { order(created_at: :desc) }

  private

  def reporter_is_not_the_host
    return if listing.nil? || reporter.nil?

    errors.add(:reporter, "cannot report their own listing") if listing.host == reporter
  end
end
