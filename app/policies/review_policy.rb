# Reviews are public. A seeker writes one only about their own completed visit (the model also checks
# it, with an explanation for the form); the author or a moderator deletes it.
class ReviewPolicy < BasePolicy
  def index? = true
  def show? = true

  # Without a visit the model answers with a validation error next to the field.
  def create? = signed_in? && (record.visit.nil? || own_completed_visit?)
  def destroy? = author? || moderator?

  private

  def author? = signed_in? && record.author_id == user.id

  def own_completed_visit?
    record.visit.completed? && record.visit.application.seeker_id == user.id
  end

  class Scope < Scope
    def resolve = scope.all
  end
end
