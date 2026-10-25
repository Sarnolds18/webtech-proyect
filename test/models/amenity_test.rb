require "test_helper"

class AmenityTest < ActiveSupport::TestCase
  test "the icon is a Bootstrap Icons class" do
    amenity = amenities(:wifi)

    amenity.icon = "bi-wifi-2"
    assert amenity.valid?

    amenity.icon = ""
    assert amenity.valid?

    [ "wifi", "bi-wifi\" onmouseover=\"alert(1)", "bi bi-wifi" ].each do |icon|
      amenity.icon = icon
      assert_not amenity.valid?, "#{icon.inspect} should be invalid"
    end
  end
end
