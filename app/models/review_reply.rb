class ReviewReply < ApplicationRecord
  belongs_to :review
  belongs_to :author, class_name: "User"

  validates :comment, presence: true
  validates :review_id, uniqueness: { message: "already has a reply" }
  validate :author_must_be_the_host

  private

  def author_must_be_the_host
    host = review&.property&.host
    return if author.nil? || host.nil? || author == host

    errors.add(:author, "must be the host of the reviewed property")
  end
end
