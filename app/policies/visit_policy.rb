# Visits live inside an application, so only its two sides act on them: the host proposes, reschedules
# and completes; the applicant confirms; either of them cancels.
class VisitPolicy < BasePolicy
  def show? = host? || seeker? || moderator?

  # The record is the new visit, built on its application.
  def create? = host?
  def confirm? = seeker?
  def cancel? = host? || seeker?
  def reschedule? = host?
  def complete? = host?

  private

  def host? = signed_in? && record.application.listing.host.id == user.id
  def seeker? = signed_in? && record.application.seeker_id == user.id

  class Scope < Scope
    def resolve
      scope.where(application_id: ApplicationPolicy::Scope.new(user, Application).resolve.select(:id))
    end
  end
end
