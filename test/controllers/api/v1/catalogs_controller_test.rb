require "test_helper"

module Api
  module V1
    class CatalogsControllerTest < ActionDispatch::IntegrationTest
      def json
        JSON.parse(response.body)
      end

      test "lists the active neighborhoods" do
        Neighborhood.create!(name: "Vitacura", city: "Santiago", active: false)

        get api_v1_neighborhoods_path

        assert_response :ok
        assert_equal [
          { "id" => neighborhoods(:providencia).id, "name" => "Providencia", "city" => "Santiago" },
          { "id" => neighborhoods(:nunoa).id, "name" => "Ñuñoa", "city" => "Santiago" }
        ].sort_by { it["id"] }, json["data"].sort_by { it["id"] }

        # Alphabetical by name, as the database sorts it: where "Ñ" falls depends on the collation of
        # each PostgreSQL install, so the expected order is read from the same database.
        assert_equal Neighborhood.active.alphabetical.pluck(:id), json["data"].pluck("id")
      end

      test "lists the active amenities" do
        amenities(:washer).update!(active: false)

        get api_v1_amenities_path

        assert_response :ok
        assert_equal [ { "id" => amenities(:wifi).id, "name" => "WiFi", "icon" => "bi-wifi" } ], json["data"]
      end
    end
  end
end
