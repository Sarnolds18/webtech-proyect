require "test_helper"

class AmenitiesControllerTest < ActionDispatch::IntegrationTest
  test "everyone sees the catalog, only moderators the management links" do
    get amenities_path
    assert_response :success
    assert_select "td", text: /WiFi/
    assert_select "a", text: "Edit", count: 0
    assert_select "a", text: /New amenity/, count: 0
    assert_select "nav a", text: "Amenities", count: 0

    act_as users(:moderator)
    get amenities_path
    assert_select "a", text: "Edit", count: 2
    assert_select "a", text: /New amenity/
    assert_select "nav a", text: "Amenities"
  end

  test "a member who opens the form by URL is sent back" do
    act_as users(:seeker)
    get new_amenity_path

    assert_redirected_to root_path
    assert_equal "Only moderators can do that.", flash[:alert]
    assert_no_difference -> { Amenity.count } do
      delete amenity_path(amenities(:wifi))
    end
  end

  test "a moderator creates an amenity" do
    act_as users(:moderator)

    assert_difference -> { Amenity.count } do
      post amenities_path, params: { amenity: { name: "Bike storage", icon: "bi-bicycle", active: "1" } }
    end
    assert_redirected_to amenities_path
  end

  test "an invalid icon renders the form again" do
    act_as users(:moderator)
    post amenities_path, params: { amenity: { name: "Gym", icon: "dumbbell" } }

    assert_response :unprocessable_entity
    assert_select "#icon_error", /Bootstrap Icons class/
  end

  test "a moderator updates an amenity" do
    act_as users(:moderator)
    patch amenity_path(amenities(:washer)), params: { amenity: { active: "0" } }

    assert_redirected_to amenities_path
    assert_not amenities(:washer).reload.active?
  end

  test "deleting an amenity removes it from its properties" do
    act_as users(:moderator)

    assert_difference -> { Amenity.count }, -1 do
      delete amenity_path(amenities(:wifi))
    end
    assert_empty properties(:flat).reload.amenities
  end
end
