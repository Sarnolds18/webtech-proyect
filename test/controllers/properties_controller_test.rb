require "test_helper"

class PropertiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @property = properties(:flat)
  end

  def property_params(**overrides)
    { title: "Sunny flat in Ñuñoa", address: "Irarrázaval 3400, depto 81", neighborhood_id: neighborhoods(:nunoa).id,
      property_type: "apartment", bedrooms: 2, bathrooms: 1, shared_spaces: "Living room and kitchen",
      amenity_ids: [ amenities(:wifi).id, amenities(:washer).id ] }.merge(overrides)
  end

  test "visitors are asked to choose a user before creating a property" do
    get new_property_path

    assert_redirected_to root_path
    assert_equal "Choose a user in the navbar first.", flash[:alert]
  end

  test "the acting user creates a property with amenities and becomes its host" do
    act_as users(:seeker)
    get new_property_path
    assert_response :success
    assert_select "select#property_neighborhood_id"
    assert_select "select#property_property_type"
    assert_select "input[type=checkbox][name='property[amenity_ids][]']", count: 2

    assert_difference -> { Property.count } do
      post properties_path, params: { property: property_params }
    end

    property = Property.last
    assert_redirected_to property_path(property)
    assert_equal users(:seeker), property.host
    assert_equal [ amenities(:washer), amenities(:wifi) ].sort_by(&:id), property.amenities.sort_by(&:id)
  end

  test "invalid properties render the form again with the errors next to each field" do
    act_as users(:seeker)

    assert_no_difference -> { Property.count } do
      post properties_path, params: { property: property_params(address: "", bedrooms: 0) }
    end

    assert_response :unprocessable_entity
    assert_select "#property_address.is-invalid"
    assert_select "#address_error", /can't be blank/
    assert_select "#bedrooms_error"
  end

  test "the host updates the amenities of a property" do
    act_as users(:host)
    get edit_property_path(@property)
    assert_select "input[type=checkbox][value='#{amenities(:wifi).id}'][checked]"
    assert_select "input[type=checkbox][value='#{amenities(:washer).id}']:not([checked])"

    patch property_path(@property), params: { property: { amenity_ids: [ "", amenities(:washer).id ] } }

    assert_redirected_to property_path(@property)
    assert_equal [ amenities(:washer) ], @property.reload.amenities
  end

  test "only the host can edit a property" do
    act_as users(:seeker)
    get edit_property_path(@property)
    assert_redirected_to property_path(@property)
    assert_equal "Only the host of this property can change it.", flash[:alert]

    patch property_path(@property), params: { property: { title: "Mine now" } }
    assert_not_equal "Mine now", @property.reload.title
  end

  test "a property with listings cannot be deleted" do
    act_as users(:host)

    assert_no_difference -> { Property.count } do
      delete property_path(@property)
    end
    assert_redirected_to property_path(@property)
    assert flash[:alert].present?
  end

  test "a property without listings is deleted" do
    act_as users(:host)
    property = Property.create!(property_params(host: users(:host)))

    assert_difference -> { Property.count }, -1 do
      delete property_path(property)
    end
    assert_redirected_to properties_path
  end

  test "the host sees every listing of the property, everyone else only the published ones" do
    listings(:cheap).update!(status: :reserved)

    get property_path(@property)
    assert_select "a", text: listings(:draft).title, count: 0
    assert_select "a", text: listings(:cheap).title, count: 0
    assert_select "a", text: "New listing", count: 0
    assert_select "a", text: "Edit", count: 0

    act_as users(:host)
    get property_path(@property)
    assert_select "a", text: listings(:draft).title
    assert_select "a", text: listings(:cheap).title
    assert_select "a", text: "New listing"
    assert_select "a", text: "Edit"
  end
end
