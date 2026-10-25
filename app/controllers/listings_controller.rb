class ListingsController < ApplicationController
  before_action :require_user, except: %i[index show]
  before_action :set_property, only: %i[new create]
  before_action :set_listing, except: %i[index new create]
  before_action :require_host, except: %i[index show withdraw]
  before_action :require_host_or_moderator, only: :withdraw

  # Only published listings are searchable.
  def index
    @listings = Listing.published.with_attached_photos.includes(property: :neighborhood)
                       .in_neighborhood(params[:neighborhood_id])
                       .under_rent(params[:max_rent])
                       .available_by(params[:available_from])
                       .soonest_available
    @neighborhoods = Neighborhood.active.alphabetical
  end

  # A draft is visible only to its host.
  def show
    return redirect_to listings_path, alert: "That listing is not available." unless @listing.visible_to?(current_user)

    @reviews = @listing.property.reviews.includes(:author, reply: :author).recent_first
  end

  # New listings start as drafts (the column default) until the host publishes them.
  def new
    @listing = @property.listings.new(available_from: Date.current, minimum_stay_months: 1)
  end

  def create
    @listing = @property.listings.new(listing_params)

    if @listing.save
      redirect_to @listing, notice: "The listing was saved as a draft. Only you can see it until you publish it."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @listing.update(listing_params)
      redirect_to @listing, notice: "The listing was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @listing.destroy
      redirect_to @listing.property, notice: "The listing was deleted."
    else
      redirect_to @listing, alert: @listing.errors.full_messages.to_sentence
    end
  end

  def publish
    transition(:publish!, "The listing is published and can receive applications.")
  end

  def withdraw
    transition(:withdraw!, "The listing was withdrawn. Applications still waiting for an answer were rejected.")
  end

  def mark_rented
    transition(:mark_rented!, "The listing is marked as rented.")
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  end

  def set_listing
    @listing = Listing.with_attached_photos.includes(property: %i[neighborhood amenities]).find(params[:id])
    @property = @listing.property
  end

  # Only the host creates, edits, deletes or moves a listing through its lifecycle; a moderator can
  # also withdraw it. Assignment 4 moves these checks to a Pundit policy.
  def require_host
    deny_listing_management unless @property.host == current_user
  end

  def require_host_or_moderator
    deny_listing_management unless @property.host == current_user || current_user.moderator?
  end

  def deny_listing_management
    redirect_to (@listing&.visible_to?(current_user) ? @listing : @property),
                alert: "Only the host of this property can manage its listings."
  end

  def transition(event, notice)
    @listing.public_send(event)
    redirect_to @listing, notice: notice
  rescue ActiveRecord::RecordInvalid
    redirect_to @listing, alert: @listing.errors.full_messages.to_sentence
  end

  def listing_params
    params.expect(listing: [ :title, :monthly_rent, :deposit, :available_from, :minimum_stay_months, :furnished,
                             :private_bathroom, :description, :house_rules, photos: [] ])
  end
end
