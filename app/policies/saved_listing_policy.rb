# A member's saved listings are their own bookmarks. A listing can be saved only when the member can
# see it (never somebody else's draft), and never by its own host.
class SavedListingPolicy < BasePolicy
  def index? = signed_in?
  def create? = signed_in? && record.listing.visible_to?(user) && record.listing.host != user
  def destroy? = signed_in? && record.user_id == user.id

  class Scope < Scope
    def resolve = user ? scope.where(user_id: user.id) : scope.none
  end
end
