module Api
  module V1
    # The active neighborhoods, to build the neighborhood filter of /api/v1/listings.
    class NeighborhoodsController < BaseController
      def index
        @neighborhoods = Neighborhood.active.alphabetical
      end
    end
  end
end
