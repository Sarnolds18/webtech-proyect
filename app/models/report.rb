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
  scope :resolved, -> { where.not(status: :open) }

  # Only open reports wait for a decision.
  def resolvable?
    open?
  end

  # The moderator decides the report is not a problem. The decision and its log entry are saved
  # together or not at all.
  def dismiss!(moderator:, notes: nil)
    transaction do
      ensure_resolvable!
      dismissed!
      ModerationAction.create!(moderator:, report: self, target_listing: listing, target_user: listing.host,
                               action_type: :dismiss_report, notes: notes.presence)
    end
  end

  # The moderator agrees: the listing is withdrawn (rejecting the applications still waiting) and every
  # open report on it is closed, all or nothing.
  def take_action!(moderator:, notes: nil)
    transaction do
      ensure_resolvable!
      listing.withdraw! if listing.withdrawable?
      listing.reports.unresolved.update_all(status: "action_taken", updated_at: Time.current)
      reload
      ModerationAction.create!(moderator:, report: self, target_listing: listing, target_user: listing.host,
                               action_type: :withdraw_listing, notes: notes.presence)
    end
  end

  private

  def ensure_resolvable!
    return if resolvable?

    errors.add(:status, "is already #{status.humanize(capitalize: false)}")
    raise ActiveRecord::RecordInvalid, self
  end

  def reporter_is_not_the_host
    return if listing.nil? || reporter.nil?

    errors.add(:reporter, "cannot report their own listing") if listing.host == reporter
  end
end
