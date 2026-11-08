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
        ], json["data"]
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
