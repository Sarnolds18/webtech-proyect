# The amenity catalog: everyone browses it, only moderators manage it.
class AmenityPolicy < BasePolicy
  def index? = true
  def show? = true
  def create? = moderator?
  def update? = moderator?
  def destroy? = moderator?

  class Scope < Scope
    def resolve = scope.all
  end
end
