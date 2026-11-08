# The host's inbox for one listing: every application it received, answered with Turbo Streams by
# ApplicationsController#shortlist, #reject and #accept. Moderators can open it too, but only read it.
class InboxesController < ApplicationController
  before_action :require_user
  before_action :set_listing
  after_action :verify_authorized
  after_action :verify_policy_scoped

  def show
    authorize @listing, :inbox?
    @applications = policy_scope(Application).where(listing: @listing).includes(:seeker).recent_first
  end

  private

  def set_listing
    @listing = Listing.includes(property: :neighborhood).find(params[:listing_id])
  end
end
