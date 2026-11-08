# The policy of the Application model (a seeker applying to a listing), not the Pundit base class: that
# one is BasePolicy.
#
# Applications are private: only the seeker who wrote one, the host of the listing and the moderators
# see it. Only the host answers it (a moderator cannot accept somebody else's applicant), and only the
# seeker withdraws it.
class ApplicationPolicy < BasePolicy
  def index? = signed_in?
  def show? = seeker? || host? || moderator?

  # Any member applies, except to their own listing.
  def create? = signed_in? && !host?

  def withdraw? = seeker?

  def answer? = host?
  def shortlist? = answer?
  def reject? = answer?
  def accept? = answer?

  private

  def seeker? = signed_in? && record.seeker_id == user.id
  def host? = signed_in? && record.listing&.host&.id == user.id

  # The query itself returns only what the user may read: what they sent plus what their listings
  # received. Visitors get nothing.
  class Scope < Scope
    def resolve
      if moderator?
        scope.all
      elsif user
        received = Listing.joins(:property).where(properties: { host_id: user.id }).select(:id)
        scope.where(seeker_id: user.id).or(scope.where(listing_id: received))
      else
        scope.none
      end
    end
  end
end
