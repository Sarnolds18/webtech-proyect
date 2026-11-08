# The audit log of what moderators did. Written by the app, read only by moderators.
class ModerationActionPolicy < BasePolicy
  def index? = moderator?
  def show? = moderator?

  class Scope < Scope
    def resolve = moderator? ? scope.all : scope.none
  end
end
