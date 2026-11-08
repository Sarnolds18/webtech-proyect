# The host of the property answers a review of it; the reply is deleted by its author or a moderator.
class ReviewReplyPolicy < BasePolicy
  def show? = true
  def create? = signed_in? && record.review.property.host_id == user.id
  def destroy? = (signed_in? && record.author_id == user.id) || moderator?

  class Scope < Scope
    def resolve = scope.all
  end
end
