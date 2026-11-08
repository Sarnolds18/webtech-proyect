class PropertiesController < ApplicationController
  before_action :require_user, except: %i[index show]
  before_action :set_property, only: %i[show edit update destroy]
  before_action :set_form_options, only: %i[new create edit update]
  after_action :verify_authorized, except: :index

  def index
    @properties = Property.includes(:neighborhood, :host, :listings).order(:title)
  end

  def show
    authorize @property
    # The policy scope hides the drafts from everyone but the host and the moderators.
    @listings = policy_scope(@property.listings).with_attached_photos.soonest_available
    @reviews = @property.reviews.includes(:author, reply: :author).recent_first
  end

  def new
    @property = authorize current_user.properties.new
  end

  def create
    @property = authorize current_user.properties.new(property_params)

    if @property.save
      redirect_to @property, notice: "The property was created. Add a listing to start receiving applications."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @property
  end

  def update
    authorize @property
    if @property.update(property_params)
      redirect_to @property, notice: "The property was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @property
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
