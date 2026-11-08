class ListingsController < ApplicationController
  before_action :require_user, except: %i[index show]
  before_action :set_property, only: %i[new create]
  before_action :set_listing, except: %i[index new create]
  # Every action except the public search checks ListingPolicy; this fails loudly if one forgets.
  after_action :verify_authorized, except: :index

  # Only published listings are searchable.
  def index
    @listings = Listing.published.with_attached_photos.includes(property: :neighborhood)
                       .in_neighborhood(params[:neighborhood_id])
                       .under_rent(params[:max_rent])
                       .available_by(params[:available_from])
                       .soonest_available
    @neighborhoods = Neighborhood.active.alphabetical
  end

  # A draft is visible only to its host and the moderators.
  def show
    authorize @listing
    @reviews = @listing.property.reviews.includes(:author, reply: :author).recent_first
  end

  # New listings start as drafts (the column default) until the host publishes them.
  def new
    @listing = authorize @property.listings.new(available_from: Date.current, minimum_stay_months: 1)
  end

  def create
    @listing = authorize @property.listings.new(listing_params)

    if @listing.save
      redirect_to @listing, notice: "The listing was saved as a draft. Only you can see it until you publish it."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @listing
  end

  def update
    authorize @listing
    if @listing.update(listing_params)
      redirect_to @listing, notice: "The listing was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @listing
    if @listing.destroy
      redirect_to @listing.property, notice: "The listing was deleted."
    else
      redirect_to @listing, alert: @listing.errors.full_messages.to_sentence
    end
  end

  def publish
    authorize @listing
    transition("The listing is published and can receive applications.") { @listing.publish! }
  end

  # A moderator can withdraw any listing; when they do it for somebody else's listing, it is logged.
  def withdraw
    authorize @listing
    transition("The listing was withdrawn. Applications still waiting for an answer were rejected.") do
      Listing.transaction do
        @listing.withdraw!
        unless @listing.host == current_user
          ModerationAction.create!(moderator: current_user, action_type: :withdraw_listing, target_listing: @listing,
                                   target_user: @listing.host, notes: "Withdrawn from the listing page")
        end
      end
    end
  end

  def mark_rented
    authorize @listing
    transition("The listing is marked as rented.") { @listing.mark_rented! }
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  end

  def set_listing
    @listing = Listing.with_attached_photos.includes(property: %i[neighborhood amenities]).find(params[:id])
    @property = @listing.property
  end

  def transition(notice)
    yield
    redirect_to @listing, notice: notice
  rescue ActiveRecord::RecordInvalid
    redirect_to @listing, alert: @listing.errors.full_messages.to_sentence
  end

  def listing_params
    params.expect(listing: [ :title, :monthly_rent, :deposit, :available_from, :minimum_stay_months, :furnished,
                             :private_bathroom, :description, :house_rules, photos: [] ])
  end
end
