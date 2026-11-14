# A member's bookmarks. The Save button on the listing page saves and unsaves without reloading: a
# Turbo Stream replaces the button. Saving twice or unsaving something that is not saved does nothing,
# so double clicks and two tabs are harmless.
class SavedListingsController < ApplicationController
  before_action :require_user
  before_action :set_listing
  after_action :verify_authorized

  def create
    saved_listing = authorize current_user.saved_listings.find_or_initialize_by(listing: @listing)
    saved_listing.save! if saved_listing.new_record?
    respond_with_button(saved: true, notice: "The listing was saved.")
  rescue ActiveRecord::RecordNotUnique
    # The same listing was saved from another tab a moment ago: it is saved, which is what was asked.
    respond_with_button(saved: true, notice: "The listing was saved.")
  end

  def destroy
    saved_listing = current_user.saved_listings.find_by(listing: @listing)
    authorize(saved_listing || current_user.saved_listings.build(listing: @listing))
    saved_listing&.destroy!
    respond_with_button(saved: false, notice: "Removed from your saved listings.")
  end

  private

  # Somebody else's draft does not exist for this member, so it gives the same 403 as any hidden draft.
  def set_listing
    @listing = Listing.includes(:property).find(params[:listing_id])
  end

  def respond_with_button(saved:, notice:)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(helpers.dom_id(@listing, :save), partial: "saved_listings/button",
                                                                                    locals: { listing: @listing, saved: saved })
      end
      format.html { redirect_back_or_to @listing, notice: notice }
    end
  end
end
