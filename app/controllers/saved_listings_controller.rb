# A member's bookmarks. The Save button on the listing page saves and unsaves without reloading: a
# Turbo Stream replaces the button. On the /saved page unsaving also removes the card. Saving twice
# or unsaving something that is not saved does nothing, so double clicks and two tabs are harmless.
class SavedListingsController < ApplicationController
  before_action :require_user
  before_action :set_listing, only: %i[create destroy]
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def index
    @saved_listings = policy_scope(SavedListing)
                        .includes(listing: [ { property: :neighborhood }, { photos_attachments: :blob } ])
                        .order(created_at: :desc)
  end

  def create
    saved_listing = authorize current_user.saved_listings.find_or_initialize_by(listing: @listing)
    saved_listing.save! if saved_listing.new_record?
    respond_with_button(saved: true, notice: "Saved. You will find it in your saved listings.")
  rescue ActiveRecord::RecordNotUnique
    # The same listing was saved from another tab a moment ago: it is saved, which is what was asked.
    respond_with_button(saved: true, notice: "Saved. You will find it in your saved listings.")
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
        streams = [ turbo_stream.replace(helpers.dom_id(@listing, :save), partial: "saved_listings/button",
                                                                          locals: { listing: @listing, saved: saved }) ]
        unless saved
          # Only the /saved page has these targets; on the listing page Turbo ignores them.
          streams << turbo_stream.remove(helpers.dom_id(@listing, :saved_card))
          if current_user.saved_listings.none?
            streams << turbo_stream.update("saved_listings", partial: "saved_listings/empty")
          end
        end
        render turbo_stream: streams
      end
      format.html { redirect_back_or_to @listing, notice: notice }
    end
  end
end
