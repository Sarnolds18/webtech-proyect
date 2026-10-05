require "test_helper"

class PropertyTest < ActiveSupport::TestCase
  setup do
    @property = properties(:flat)
  end

  test "fixture is valid" do
    assert @property.valid?
  end

  test "needs at least one bedroom and one bathroom" do
    @property.bedrooms = 0
    @property.bathrooms = 0

    assert_not @property.valid?
    assert @property.errors.key?(:bedrooms)
    assert @property.errors.key?(:bathrooms)
  end

  test "amenities through property_amenities, in both directions" do
    assert_includes @property.amenities, amenities(:wifi)
    assert_includes amenities(:wifi).properties, @property
  end

  test "an amenity cannot be added twice" do
    duplicate = @property.property_amenities.build(amenity: amenities(:wifi))

    assert_not duplicate.valid?
  end

  test "average rating of its reviews" do
    assert_equal 4.0, properties(:house).average_rating
    assert_nil @property.average_rating
  end

  test "cannot be deleted while it has listings" do
    assert_not @property.destroy
    assert @property.errors.any?
  end
end
