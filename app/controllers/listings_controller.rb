class ListingsController < ApplicationController
  before_action :set_listing, only: :show

  # The index lists published listings only. The show page opens a listing in any state and
  # displays that state, so the rest of the lifecycle can be browsed too.
  def index
    @listings = Listing.published.includes(property: :neighborhood)
                       .in_neighborhood(params[:neighborhood_id])
                       .under_rent(params[:max_rent])
                       .available_by(params[:available_from])
                       .soonest_available
    @neighborhoods = Neighborhood.active.alphabetical
  end

  def show
    @reviews = @listing.property.reviews.includes(:author, reply: :author).recent_first
  end

  private

  def set_listing
    @listing = Listing.includes(property: %i[neighborhood amenities]).find(params[:id])
  end
end
