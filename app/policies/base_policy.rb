# Every policy inherits from here. Pundit looks up `ApplicationPolicy` for the Application model, so
# the shared base is called BasePolicy instead of the generator's name.
#
# Visitors (nobody signed in) arrive as `user == nil`, so every rule must answer for nil. Ownership,
# not the role, decides most permissions; moderators get a few extra powers on top of a member's.
class BasePolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Closed by default: each policy opens only what the permission table allows.
  def index? = false
  def show? = false
  def create? = false
  def new? = create?
  def update? = false
  def edit? = update?
  def destroy? = false

  private

  def signed_in? = user.present?
  def moderator? = user&.moderator? || false

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope

    def moderator? = user&.moderator? || false
  end
end
