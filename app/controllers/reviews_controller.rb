# A seeker reviews a property after their own completed visit (ReviewPolicy, and the model explains any
# problem with the form). The author or a moderator deletes a review; a moderator's deletion is logged.
class ReviewsController < ApplicationController
  before_action :require_user
  before_action :set_property, only: :create
  after_action :verify_authorized

  def create
    @review = authorize Review.new(review_params.merge(author: current_user))

    if @review.save
      redirect_to @review.property, notice: "Thank you! Your review was published."
    else
      @listings = policy_scope(@property.listings).with_attached_photos.soonest_available
      @reviews = @property.reviews.includes(:author, reply: :author).recent_first
      render "properties/show", status: :unprocessable_entity
    end
  end

  # The review row is deleted, so a moderator's log entry keeps what it said in its notes.
  def destroy
    review = authorize Review.includes(:author, :property).find(params[:id])

    Review.transaction do
      review.destroy!
      unless review.author == current_user
        ModerationAction.create!(moderator: current_user, action_type: :remove_review, target_user: review.author,
                                 notes: "Removed a #{review.rating}-star review of #{review.property.title}: " \
                                        "#{review.comment.truncate(100)}")
      end
    end

    redirect_back_or_to review.property, notice: "The review was deleted."
  end

  private

  def set_property
    @property = Property.includes(:neighborhood, :host, :amenities).find(params[:property_id])
  end

  # Only visits to this property are reviewed from its page; the model explains any other problem.
  def review_params
    params.expect(review: %i[visit_id rating comment]).tap do |attributes|
      visits_here = Visit.joins(:application).where(applications: { listing_id: @property.listings.select(:id) })
      attributes[:visit_id] = nil unless visits_here.exists?(attributes[:visit_id])
    end
  end
end
