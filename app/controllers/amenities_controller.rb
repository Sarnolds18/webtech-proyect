# The amenity catalog: everyone browses it, only moderators manage it.
class AmenitiesController < ApplicationController
  before_action :require_moderator, except: :index
  before_action :set_amenity, only: %i[edit update destroy]

  def index
    @amenities = Amenity.alphabetical
    # Properties per amenity, counted in one grouped query instead of one count per row.
    @property_counts = PropertyAmenity.group(:amenity_id).count
  end

  def new
    @amenity = Amenity.new
  end

  def create
    @amenity = Amenity.new(amenity_params)

    if @amenity.save
      redirect_to amenities_path, notice: "#{@amenity.name} was added to the catalog."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @amenity.update(amenity_params)
      redirect_to amenities_path, notice: "#{@amenity.name} was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Deleting an amenity also removes it from the properties that had it.
  def destroy
    @amenity.destroy!
    redirect_to amenities_path, notice: "#{@amenity.name} was deleted from the catalog."
  end

  private

  def set_amenity
    @amenity = Amenity.find(params[:id])
  end

  def amenity_params
    params.expect(amenity: %i[name icon active])
  end
end
