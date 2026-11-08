require "test_helper"

module Api
  module V1
    class ListingsControllerTest < ActionDispatch::IntegrationTest
      def json
        JSON.parse(response.body)
      end

      def titles
        json["data"].map { |listing| listing["title"] }
      end

      test "lists only published listings, as JSON" do
        get api_v1_listings_path

        assert_response :ok
        assert_equal "application/json", response.media_type
        assert_equal [ listings(:cheap).title, listings(:pricey).title ], titles
        assert_equal({ "page" => 1, "per_page" => 12, "total" => 2, "total_pages" => 1 }, json["meta"])
      end

      test "each listing carries its public data" do
        get api_v1_listing_path(listings(:pricey))

        listing = json["data"]
        assert_equal 400_000, listing["monthly_rent"]
        assert_equal "CLP", listing["currency"]
        assert_equal listings(:pricey).available_from.iso8601, listing["available_from"]
        assert listing["private_bathroom"]
        assert_equal({ "id" => neighborhoods(:nunoa).id, "name" => "Ñuñoa", "city" => "Santiago" }, listing["neighborhood"])
        assert_equal "house", listing["property"]["property_type"]
        assert_equal({ "average" => 4.0, "count" => 1 }, listing["rating"])
        assert_equal api_v1_listing_url(listings(:pricey)), listing["links"]["self"]
        assert_equal listing_url(listings(:pricey)), listing["links"]["html"]
        assert_nil listing["cover_photo_url"]
        assert_equal [], listing["photos"]
      end

      test "the detail sends the rich text as plain text" do
        listings(:cheap).update!(description: "<p>A <strong>sunny</strong> room</p>", house_rules: "<ul><li>No smoking</li></ul>")

        get api_v1_listing_path(listings(:cheap))

        assert_equal "A sunny room", json["data"]["description"]
        assert_match "No smoking", json["data"]["house_rules"]
        assert_no_match(/<strong>|<li>/, response.body)
      end

      test "photo urls are absolute" do
        listings(:cheap).photos.attach(io: file_fixture("room.jpg").open, filename: "room.jpg", content_type: "image/jpeg")

        get api_v1_listing_path(listings(:cheap))

        assert_match %r{\Ahttp://www\.example\.com/rails/active_storage/}, json["data"]["cover_photo_url"]
        assert_match %r{\Ahttp://}, json["data"]["photos"].first["large_url"]
      end

      test "never exposes personal data" do
        get api_v1_listings_path
        index_body = response.body
        get api_v1_listing_path(listings(:pricey))

        [ index_body, response.body ].each do |body|
          assert_no_match(/roomies\.test|Av\. Providencia|Jorge Washington|Valentina|Sofía/, body)
          %w[host host_id address email_address phone applications seeker author message].each do |key|
            assert_no_match(/"#{key}":/, body)
          end
        end
      end

      test "filters by neighborhood, rent, date and amenities" do
        get api_v1_listings_path(neighborhood_id: neighborhoods(:providencia).id)
        assert_equal [ listings(:cheap).title ], titles

        get api_v1_listings_path(max_rent: 300_000)
        assert_equal [ listings(:cheap).title ], titles

        get api_v1_listings_path(available_by: 20.days.from_now.to_date.iso8601)
        assert_equal [ listings(:cheap).title ], titles

        get api_v1_listings_path(amenity_ids: [ amenities(:wifi).id ])
        assert_equal [ listings(:cheap).title ], titles

        get api_v1_listings_path(amenity_ids: "#{amenities(:wifi).id},#{amenities(:washer).id}")
        assert_equal [], titles
        assert_equal 0, json["meta"]["total"]
      end

      test "filters by furnished and private bathroom" do
        listings(:cheap).update!(furnished: true)

        get api_v1_listings_path(furnished: "true")
        assert_equal [ listings(:cheap).title ], titles

        get api_v1_listings_path(private_bathroom: "true")
        assert_equal [ listings(:pricey).title ], titles

        get api_v1_listings_path(furnished: "false")
        assert_equal 2, json["meta"]["total"]
      end

      test "sorts by soonest, cheapest or newest" do
        listings(:cheap).update_columns(created_at: 2.days.ago)

        get api_v1_listings_path(sort: "cheapest")
        assert_equal [ listings(:cheap).title, listings(:pricey).title ], titles

        get api_v1_listings_path(sort: "newest")
        assert_equal [ listings(:pricey).title, listings(:cheap).title ], titles
      end

      test "paginates with meta and links" do
        get api_v1_listings_path(per_page: 1, max_rent: 500_000)

        assert_equal [ listings(:cheap).title ], titles
        assert_equal 2, json["meta"]["total_pages"]
        assert_nil json["links"]["prev"]
        assert_match "page=2", json["links"]["next"]
        assert_match "max_rent=500000", json["links"]["next"]

        get json["links"]["next"]
        assert_equal [ listings(:pricey).title ], titles
        assert_nil json["links"]["next"]
        assert_match "page=1", json["links"]["prev"]
      end

      test "invalid parameters answer 400 with the parameter that failed" do
        {
          { max_rent: "abc" } => "max_rent",
          { neighborhood_id: "-1" } => "neighborhood_id",
          { available_by: "31-12-2026" } => "available_by",
          { available_by: "2026-02-30" } => "available_by",
          { per_page: "500" } => "per_page",
          { page: "0" } => "page",
          { sort: "foo" } => "sort",
          { amenity_ids: "1,abc" } => "amenity_ids",
          { furnished: "maybe" } => "furnished"
        }.each do |params, parameter|
          get api_v1_listings_path(params)

          assert_response :bad_request, "expected 400 for #{params}"
          assert_equal "application/json", response.media_type
          assert_equal({ "status" => 400, "code" => "invalid_parameter", "parameter" => parameter },
                       json["error"].except("message"), "for #{params}")
          assert json["error"]["message"].present?
        end
      end

      test "a listing that is not published is not found" do
        get api_v1_listing_path(listings(:draft))

        assert_response :not_found
        assert_equal({ "status" => 404, "code" => "not_found" }, json["error"].slice("status", "code"))
        assert_no_match listings(:draft).title, response.body
      end

      test "a listing that does not exist is not found" do
        get api_v1_listing_path(id: 0)

        assert_response :not_found
        assert_equal "not_found", json["error"]["code"]
      end

      test "unknown endpoints answer 404 in JSON" do
        get "/api/v1/nope"

        assert_response :not_found
        assert_equal "application/json", response.media_type
        assert_equal "Unknown API endpoint.", json["error"]["message"]
      end

      test "is public: no sign in, and a signed in user sees the same" do
        act_as users(:host)

        get api_v1_listings_path

        assert_response :ok
        assert_not_includes titles, listings(:draft).title
      end
    end
  end
end
