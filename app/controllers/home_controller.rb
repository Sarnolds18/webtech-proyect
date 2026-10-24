class HomeController < ApplicationController
  def index
    @featured = Listing.published.with_attached_photos.includes(property: :neighborhood).soonest_available.limit(3)
    @neighborhoods = Neighborhood.active.alphabetical
  end
end
