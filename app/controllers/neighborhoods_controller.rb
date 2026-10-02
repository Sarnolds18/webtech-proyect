class NeighborhoodsController < ApplicationController
  before_action :set_neighborhood, only: :show

  def index
    @neighborhoods = Neighborhood.active.alphabetical
    # Published listings per neighborhood, counted in one grouped query instead of one count per row.
    @published_counts = Listing.published.joins(:property).group("properties.neighborhood_id").count
  end

  def show
    @listings = @neighborhood.listings.published.includes(property: :neighborhood).soonest_available
    @properties = @neighborhood.properties.includes(:neighborhood, :host, :listings).order(:title)
  end

  private

  def set_neighborhood
    @neighborhood = Neighborhood.find(params[:id])
  end
end
