# Any member reports a listing that is not theirs. Only moderators read and resolve the reports.
class ReportPolicy < BasePolicy
  def create? = signed_in? && record.listing.host.id != user.id
  def index? = moderator?
  def show? = moderator?
  def dismiss? = moderator?
  def take_action? = moderator?

  class Scope < Scope
    def resolve = moderator? ? scope.all : scope.none
  end
end
