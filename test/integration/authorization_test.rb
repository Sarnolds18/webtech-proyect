require "test_helper"

class AuthorizationTest < ActionDispatch::IntegrationTest
  test "a member cannot edit somebody else's property or listing, a moderator can" do
    act_as users(:seeker)
    patch property_path(properties(:flat)), params: { property: { title: "Mine now" } }
    assert_response :forbidden
    patch listing_path(listings(:cheap)), params: { listing: { title: "Mine now" } }
    assert_response :forbidden
    assert_not_equal "Mine now", listings(:cheap).reload.title

    act_as users(:moderator)
    patch listing_path(listings(:cheap)), params: { listing: { title: "Room in Providencia" } }
    assert_equal "Room in Providencia", listings(:cheap).reload.title
  end

  test "a member cannot create a neighborhood" do
    act_as users(:seeker)

    assert_no_difference -> { Neighborhood.count } do
      post neighborhoods_path, params: { neighborhood: { name: "Vitacura", city: "Santiago" } }
    end
    assert_response :forbidden
  end

  test "the property page lists drafts only for the host and the moderators" do
    get property_path(properties(:flat))
    assert_select "a", text: listings(:draft).title, count: 0

    act_as users(:moderator)
    get property_path(properties(:flat))
    assert_select "a", text: listings(:draft).title
    assert_select "a", text: "Edit"
  end
end
