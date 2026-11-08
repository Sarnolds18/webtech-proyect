module Api
  module V1
    # Published listings only: any other state answers 404, exactly like an id that does not exist.
    class ListingsController < BaseController
      DEFAULT_PER_PAGE = 12
      MAX_PER_PAGE = 50
      SORTS = {
        "soonest" => { available_from: :asc },
        "cheapest" => { monthly_rent: :asc },
        "newest" => { created_at: :desc }
      }.freeze
      BOOLEANS = { "true" => true, "1" => true, "false" => false, "0" => false }.freeze

      def index
        listings = Listing.published
                          .in_neighborhood(integer_param(:neighborhood_id))
                          .under_rent(integer_param(:max_rent))
                          .available_by(date_param(:available_by))
                          .with_amenities(amenity_ids_param)
        listings = listings.furnished_only if boolean_param(:furnished)
        listings = listings.with_private_bathroom if boolean_param(:private_bathroom)
        order = sort_param
        @page = page_param
        @per_page = per_page_param

        @total = listings.count
        @listings = listings.with_attached_photos.includes(property: %i[neighborhood amenities])
                            .order(order).order(:id).offset((@page - 1) * @per_page).limit(@per_page)
        @ratings = ratings_for(@listings)
      end

      def show
        @listing = Listing.published.with_attached_photos.includes(property: %i[neighborhood amenities])
                          .find(params[:id])
        @ratings = ratings_for([ @listing ])
      end

      private

      # Average rating and number of reviews per property, in two grouped queries for the whole page.
      def ratings_for(listings)
        property_ids = listings.map(&:property_id).uniq
        reviews = Review.where(property_id: property_ids).group(:property_id)
        averages = reviews.average(:rating)
        counts = reviews.count
        property_ids.index_with { |id| { average: averages[id]&.to_f&.round(1), count: counts.fetch(id, 0) } }
      end

      def integer_param(name)
        value = params[name]
        return if value.blank?
        unless value.is_a?(String) && value.match?(/\A\d+\z/) && value.to_i.positive?
          raise InvalidParameter.new(name, "#{name} must be a positive integer")
        end

        value.to_i
      end

      def date_param(name)
        value = params[name]
        return if value.blank?
        unless value.is_a?(String) && value.match?(/\A\d{4}-\d{2}-\d{2}\z/)
          raise InvalidParameter.new(name, "#{name} must be a date in YYYY-MM-DD format")
        end

        Date.strptime(value, "%Y-%m-%d")
      rescue Date::Error
        raise InvalidParameter.new(name, "#{name} must be a date in YYYY-MM-DD format")
      end

      def boolean_param(name)
        value = params[name]
        return false if value.blank?

        BOOLEANS.fetch(value.to_s.downcase) { raise InvalidParameter.new(name, "#{name} must be true or false") }
      end

      # Both `amenity_ids[]=1&amenity_ids[]=3` and `amenity_ids=1,3`.
      def amenity_ids_param
        value = params[:amenity_ids]
        ids = case value
        when nil then []
        when String then value.split(",").map(&:strip)
        when Array then value
        else raise InvalidParameter.new(:amenity_ids, "amenity_ids must be a list of positive integers")
        end
        ids = ids.compact_blank
        unless ids.all? { |id| id.is_a?(String) && id.match?(/\A\d+\z/) && id.to_i.positive? }
          raise InvalidParameter.new(:amenity_ids, "amenity_ids must be a list of positive integers")
        end

        ids
      end

      def sort_param
        SORTS.fetch(params.fetch(:sort, "soonest").to_s) do
          raise InvalidParameter.new(:sort, "sort must be one of: #{SORTS.keys.join(", ")}")
        end
      end

      def page_param
        integer_param(:page) || 1
      end

      def per_page_param
        per_page = integer_param(:per_page) || DEFAULT_PER_PAGE
        raise InvalidParameter.new(:per_page, "per_page must be at most #{MAX_PER_PAGE}") if per_page > MAX_PER_PAGE

        per_page
      end
    end
  end
end
