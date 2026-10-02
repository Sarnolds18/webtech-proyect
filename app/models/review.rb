class Review < ApplicationRecord
  belongs_to :visit
  belongs_to :property
  belongs_to :author, class_name: "User"
  has_one :reply, class_name: "ReviewReply", dependent: :destroy

  before_validation :set_property_from_visit, on: :create

  validates :rating, numericality: { only_integer: true, in: 1..5 }
  validates :comment, presence: true
  validates :visit_id, uniqueness: { message: "already has a review" }
  validate :visit_must_be_completed
  validate :author_must_be_the_seeker
  validate :author_cannot_be_the_host

  scope :recent_first, -> { order(created_at: :desc) }

  private

  def set_property_from_visit
    self.property ||= visit&.application&.listing&.property
  end

  def visit_must_be_completed
    return if visit.nil? || visit.completed?

    errors.add(:visit, "must be completed before it can be reviewed")
  end

  def author_must_be_the_seeker
    seeker = visit&.application&.seeker
    return if author.nil? || seeker.nil? || author == seeker

    errors.add(:author, "must be the seeker who made the visit")
  end

  def author_cannot_be_the_host
    return if author.nil? || property.nil?

    errors.add(:author, "cannot review their own property") if author == property.host
  end
end
