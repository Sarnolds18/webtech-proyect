class ModerationAction < ApplicationRecord
  belongs_to :moderator, class_name: "User"
  belongs_to :report, optional: true
  belongs_to :target_listing, class_name: "Listing", optional: true
  belongs_to :target_user, class_name: "User", optional: true

  enum :action_type, {
    dismiss_report: "dismiss_report",
    withdraw_listing: "withdraw_listing",
    remove_review: "remove_review",
    suspend_user: "suspend_user"
  }

  validates :action_type, presence: true
  validate :moderator_must_be_a_moderator

  scope :recent_first, -> { order(created_at: :desc) }

  private

  def moderator_must_be_a_moderator
    return if moderator.nil? || moderator.moderator?

    errors.add(:moderator, "must have the moderator role")
  end
end
