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

  test "the listings page is wired to search through the API with fetch" do
    get listings_path

    assert_select "[data-controller='listing-search'][data-listing-search-url-value='#{api_v1_listings_path}']" do
      assert_select "form[data-listing-search-target='form'][action='#{listings_path}'][method='get']"
      assert_select "form[data-action*='input->listing-search#search'][data-action*='submit->listing-search#submit']"
      assert_select "[data-listing-search-target='results'] .listing-card", 2
      assert_select "[data-listing-search-target='count'][aria-live='polite']", text: /2 rooms found/
      assert_select "[data-listing-search-target='empty'].d-none"
      assert_select "button[data-listing-search-target='more'][data-action='listing-search#loadMore']"
      assert_select "template[data-listing-search-target='template']"
    end
  end

  test "the card template has a slot for every field the script fills in" do
    get listings_path

    template = Nokogiri::HTML5.fragment(css_select("template[data-listing-search-target='template']").first.inner_html)
    %w[photo neighborhood rent title property available].each do |field|
      assert template.at_css("[data-field='#{field}']"), "missing data-field=#{field}"
    end
  end

  test "the home search stays a plain GET to the listings page" do
    get root_path

    assert_select "form[action='#{listings_path}'][method='get']"
    assert_select "form[data-listing-search-target]", count: 0
  end
end
