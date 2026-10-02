class HomeController < ApplicationController
  def index
    @featured = Listing.published.includes(property: :neighborhood).soonest_available.limit(3)
    @neighborhoods = Neighborhood.active.alphabetical
  end
end
