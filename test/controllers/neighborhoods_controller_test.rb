require "test_helper"

class NeighborhoodsControllerTest < ActionDispatch::IntegrationTest
  test "a moderator creates a neighborhood" do
    act_as users(:moderator)
    get new_neighborhood_path
    assert_response :success

    assert_difference -> { Neighborhood.count } do
      post neighborhoods_path, params: { neighborhood: { name: "Vitacura", city: "Santiago", active: "1" } }
    end
    assert_redirected_to neighborhood_path(Neighborhood.last)
    assert_equal "Vitacura was added to the catalog.", flash[:notice]
  end

  test "members and visitors cannot manage the catalog, even by URL" do
    get new_neighborhood_path
    assert_redirected_to root_path
    assert_equal "Only moderators can do that.", flash[:alert]

    act_as users(:seeker)
    get new_neighborhood_path
    assert_redirected_to root_path

    assert_no_difference -> { Neighborhood.count } do
      post neighborhoods_path, params: { neighborhood: { name: "Vitacura", city: "Santiago" } }
    end
    patch neighborhood_path(neighborhoods(:nunoa)), params: { neighborhood: { name: "Renamed" } }
    assert_equal "Ñuñoa", neighborhoods(:nunoa).reload.name
  end

  test "only moderators see the management links" do
    get neighborhoods_path
    assert_select "a", text: /New neighborhood/, count: 0
    get neighborhood_path(neighborhoods(:nunoa))
    assert_select "a", text: "Edit", count: 0

    act_as users(:moderator)
    get neighborhoods_path
    assert_select "a", text: /New neighborhood/
    get neighborhood_path(neighborhoods(:nunoa))
    assert_select "a", text: "Edit"
    assert_select "button", text: "Delete"
  end

  test "a duplicate neighborhood renders the form again" do
    act_as users(:moderator)
    post neighborhoods_path, params: { neighborhood: { name: "Providencia", city: "Santiago" } }

    assert_response :unprocessable_entity
    assert_select "#name_error", /already been taken/
  end

  test "a deactivated neighborhood leaves the active list but stays reachable for moderators" do
    act_as users(:moderator)
    neighborhood = neighborhoods(:nunoa)
    patch neighborhood_path(neighborhood), params: { neighborhood: { active: "0" } }

    assert_redirected_to neighborhood_path(neighborhood)
    assert_not neighborhood.reload.active?
    get neighborhoods_path
    assert_select "#inactive-heading + ul a", text: "Ñuñoa, Santiago"
  end

  test "a neighborhood with properties cannot be deleted" do
    act_as users(:moderator)

    assert_no_difference -> { Neighborhood.count } do
      delete neighborhood_path(neighborhoods(:providencia))
    end
    assert_redirected_to neighborhood_path(neighborhoods(:providencia))
    assert_equal "Cannot delete record because dependent properties exist", flash[:alert]
  end

  test "an empty neighborhood is deleted" do
    act_as users(:moderator)
    neighborhood = Neighborhood.create!(name: "Macul", city: "Santiago")

    assert_difference -> { Neighborhood.count }, -1 do
      delete neighborhood_path(neighborhood)
    end
    assert_redirected_to neighborhoods_path
  end
end
