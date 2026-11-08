# Published listings are public. A draft is seen only by its host and the moderators; reserved, rented
# and withdrawn listings open by their URL but are not listed. The host runs the lifecycle of their
# listings; a moderator can edit or withdraw any of them.
class ListingPolicy < BasePolicy
  def index? = true
  def show? = !record.draft? || owner? || moderator?

  # Listings are created inside a property, so only the host of that property creates them.
  def create? = owner?
  def update? = owner? || moderator?
  def destroy? = owner? || moderator?

  def publish? = owner?
  def mark_rented? = owner?
  def withdraw? = owner? || moderator?

  # The inbox shows every application the listing received.
  def inbox? = owner? || moderator?

  private

  def owner? = signed_in? && record.property&.host_id == user.id

  # The listings shown in lists: the published ones, plus every listing of the user's own properties.
  # Moderators see them all.
  class Scope < Scope
    def resolve
      if moderator?
        scope.all
      elsif user
        scope.published.or(scope.where(property_id: user.properties.select(:id)))
      else
        scope.published
      end
    end
  end
end
