# Properties are public. Any member creates one; only its host or a moderator changes it.
class PropertyPolicy < BasePolicy
  def index? = true
  def show? = true
  def create? = signed_in?
  def update? = owner? || moderator?
  def destroy? = owner? || moderator?

  private

  def owner? = signed_in? && record.host_id == user.id

  class Scope < Scope
    def resolve = scope.all
  end
end
