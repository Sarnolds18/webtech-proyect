require "test_helper"

class ListingWithAmenitiesTest < ActiveSupport::TestCase
  test "keeps the listings whose property has the amenity" do
    results = Listing.with_amenities([ amenities(:wifi).id ])

    assert_includes results, listings(:cheap)
    assert_not_includes results, listings(:pricey)
  end

  test "requires every amenity, not any of them" do
    assert_empty Listing.with_amenities([ amenities(:wifi).id, amenities(:washer).id ])

    properties(:flat).amenities << amenities(:washer)
    assert_equal [ listings(:cheap), listings(:draft) ].sort,
                 Listing.with_amenities([ amenities(:wifi).id, amenities(:washer).id ]).sort
  end

  test "accepts ids as strings and ignores repeated ones" do
    assert_includes Listing.with_amenities([ amenities(:wifi).id.to_s, amenities(:wifi).id.to_s ]), listings(:cheap)
  end

  test "returns everything when no amenity is given" do
    assert_equal Listing.count, Listing.with_amenities(nil).count
    assert_equal Listing.count, Listing.with_amenities([ "" ]).count
    assert_equal Listing.count, Listing.with_amenities([]).count
  end

  test "chains with the other filters" do
    results = Listing.published.under_rent(300_000).with_amenities([ amenities(:wifi).id ])

    assert_equal [ listings(:cheap) ], results.to_a
  end
end
