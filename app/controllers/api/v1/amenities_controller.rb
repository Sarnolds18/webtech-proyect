module Api
  module V1
    # The active amenities, to build the amenity filter of /api/v1/listings.
    class AmenitiesController < BaseController
      def index
        @amenities = Amenity.active.alphabetical
      end
    end
  end
end
