# A member's saved listings are their own bookmarks.
class SavedListingPolicy < BasePolicy
  def index? = signed_in?
  def create? = signed_in?
  def destroy? = signed_in? && record.user_id == user.id

  class Scope < Scope
    def resolve = user ? scope.where(user_id: user.id) : scope.none
  end
end
