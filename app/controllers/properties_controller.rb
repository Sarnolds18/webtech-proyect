class PropertiesController < ApplicationController
  before_action :require_user, except: %i[index show]
  before_action :set_property, only: %i[show edit update destroy]
  before_action :require_host, only: %i[edit update destroy]
  before_action :set_form_options, only: %i[new create edit update]

  def index
    @properties = Property.includes(:neighborhood, :host, :listings).order(:title)
  end

  def show
    # The host sees every listing of the property, drafts included; everyone else, the published ones.
    @listings = @property.listings.with_attached_photos.soonest_available
    @listings = @listings.published unless @property.host == current_user
    @reviews = @property.reviews.includes(:author, reply: :author).recent_first
  end

  def new
    @property = current_user.properties.new
  end

  def create
    @property = current_user.properties.new(property_params)

    if @property.save
      redirect_to @property, notice: "The property was created. Add a listing to start receiving applications."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @property.update(property_params)
      redirect_to @property, notice: "The property was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @property.destroy
      redirect_to properties_path, notice: "The property was deleted."
    else
      redirect_to @property, alert: @property.errors.full_messages.to_sentence
    end
  end

  private

  def set_property
    @property = Property.includes(:neighborhood, :host, :amenities).find(params[:id])
  end

  # Only the host edits or deletes a property. Assignment 4 moves this check to a Pundit policy.
  def require_host
    redirect_to @property, alert: "Only the host of this property can change it." unless @property.host == current_user
  end

  # Active catalog entries, plus the inactive ones this property already uses so editing keeps them.
  def set_form_options
    @neighborhoods = Neighborhood.active.or(Neighborhood.where(id: @property&.neighborhood_id)).alphabetical
    @amenities = Amenity.active.or(Amenity.where(id: @property&.amenity_ids)).alphabetical
  end

  def property_params
    params.expect(property: [ :title, :address, :neighborhood_id, :property_type, :bedrooms, :bathrooms,
                              :shared_spaces, :description, amenity_ids: [] ])
  end
end
