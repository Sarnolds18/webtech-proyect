require "test_helper"

class ActingUsersControllerTest < ActionDispatch::IntegrationTest
  test "visitors browse as nobody" do
    get listings_path

    assert_response :success
    assert_select "#user_id option[selected]", count: 0
  end

  test "choosing a user makes every page act as them" do
    patch acting_user_path, params: { user_id: users(:seeker).id }, headers: { "Referer" => listings_url }

    assert_redirected_to listings_url
    follow_redirect!
    assert_select ".alert", /acting as Sofía Araya/
    assert_select "#user_id option[selected]", text: "Sofía Araya"
  end

  test "choosing nobody goes back to browsing as a visitor" do
    patch acting_user_path, params: { user_id: users(:seeker).id }
    patch acting_user_path, params: { user_id: "" }

    follow_redirect!
    assert_select ".alert", /browsing as a visitor/
    assert_select "#user_id option[selected]", count: 0
  end
end
