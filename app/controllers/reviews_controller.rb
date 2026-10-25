# A seeker reviews a property after a completed visit. The model checks that the visit is completed,
# that the author is its seeker and not the host, and that the visit has no review yet.
class ReviewsController < ApplicationController
  before_action :require_user
  before_action :set_property

  def create
    @review = Review.new(review_params.merge(author: current_user))

    if @review.save
      redirect_to @review.property, notice: "Thank you! Your review was published."
    else
      @listings = @property.listings.with_attached_photos.soonest_available
      @listings = @listings.published unless @property.host == current_user
      @reviews = @property.reviews.includes(:author, reply: :author).recent_first
      render "properties/show", status: :unprocessable_entity
    end
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
