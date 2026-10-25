# The host's inbox for one listing: every application it received, answered with Turbo Streams by
# ApplicationsController#shortlist, #reject and #accept.
class InboxesController < ApplicationController
  before_action :require_user
  before_action :set_listing
  before_action :require_host

  def show
    @applications = @listing.applications.includes(:seeker).recent_first
  end

  private

  def set_listing
    @listing = Listing.includes(property: :neighborhood).find(params[:listing_id])
  end

  # Only the host reads the applications of a listing. Assignment 4 moves this check to a Pundit policy.
  def require_host
    return if @listing.host == current_user

    redirect_to (@listing.visible_to?(current_user) ? @listing : listings_path),
                alert: "Only the host of this listing can open its inbox."
  end
end
