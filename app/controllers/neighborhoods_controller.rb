# The neighborhood catalog: everyone browses it, only moderators manage it.
class NeighborhoodsController < ApplicationController
  before_action :require_moderator, except: %i[index show]
  before_action :set_neighborhood, only: %i[show edit update destroy]

  def index
    @neighborhoods = Neighborhood.active.alphabetical
    # Moderators also see the inactive ones, to edit or reactivate them.
    @inactive_neighborhoods = current_user&.moderator? ? Neighborhood.where(active: false).alphabetical : Neighborhood.none
    # Published listings per neighborhood, counted in one grouped query instead of one count per row.
    @published_counts = Listing.published.joins(:property).group("properties.neighborhood_id").count
  end

  def show
    @listings = @neighborhood.listings.published.with_attached_photos.includes(property: :neighborhood).soonest_available
    @properties = @neighborhood.properties.includes(:neighborhood, :host, :listings).order(:title)
  end

  def new
    @neighborhood = Neighborhood.new(city: "Santiago")
  end

  def create
    @neighborhood = Neighborhood.new(neighborhood_params)

    if @neighborhood.save
      redirect_to @neighborhood, notice: "#{@neighborhood.name} was added to the catalog."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @neighborhood.update(neighborhood_params)
      redirect_to @neighborhood, notice: "#{@neighborhood.name} was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # A neighborhood with properties cannot be deleted (restrict_with_error); it is deactivated instead.
  def destroy
    if @neighborhood.destroy
      redirect_to neighborhoods_path, notice: "#{@neighborhood.name} was deleted from the catalog."
    else
      redirect_to @neighborhood, alert: @neighborhood.errors.full_messages.to_sentence
    end
  end

  private

  def set_neighborhood
    @neighborhood = Neighborhood.find(params[:id])
  end

  def neighborhood_params
    params.expect(neighborhood: %i[name city active])
  end
end
