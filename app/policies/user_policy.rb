# A member sees and edits only their own account (the profile page always uses the signed-in user).
class UserPolicy < BasePolicy
  def show? = self? || moderator?
  def update? = self?

  private

  def self? = signed_in? && record.id == user.id
end
