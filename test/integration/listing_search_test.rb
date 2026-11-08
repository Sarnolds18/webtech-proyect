require "test_helper"

class ListingSearchTest < ActionDispatch::IntegrationTest
  test "the search filters by amenities and keeps them checked" do
    get listings_path(amenity_ids: [ amenities(:wifi).id ])

    assert_response :success
    assert_match listings(:cheap).title, response.body
    assert_no_match listings(:pricey).title, response.body
    assert_select "input[type=checkbox][name='amenity_ids[]'][value='#{amenities(:wifi).id}'][checked]"
    assert_select "input[type=checkbox][name='amenity_ids[]'][value='#{amenities(:washer).id}']:not([checked])"
  end

  test "amenities that match nothing show the empty state with a way back" do
    get listings_path(amenity_ids: [ amenities(:wifi).id, amenities(:washer).id ])

    assert_response :success
    assert_match "No rooms match your search", response.body
  end

  test "the home search offers the active amenities with a label each" do
    amenities(:washer).update!(active: false)

    get root_path

    assert_response :success
    assert_select "label[for='amenity_#{amenities(:wifi).id}']", text: /WiFi/
    assert_select "input#amenity_#{amenities(:washer).id}", count: 0
  end

  test "malformed amenity params are ignored instead of failing" do
    get listings_path, params: { amenity_ids: "abc" }
    assert_response :success

    get "#{listings_path}?amenity_ids[x]=1"
    assert_response :success
    assert_match listings(:pricey).title, response.body
  end
end
