# The neighborhood catalog: everyone browses it, only moderators manage it.
class NeighborhoodPolicy < BasePolicy
  def index? = true
  def show? = true
  def create? = moderator?
  def update? = moderator?
  def destroy? = moderator?

  class Scope < Scope
    def resolve = scope.all
  end
end
