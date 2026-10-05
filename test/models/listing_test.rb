require "test_helper"

class ListingTest < ActiveSupport::TestCase
  setup do
    @listing = listings(:cheap)
  end

  test "fixture is valid" do
    assert @listing.valid?
  end

  test "new listings start as drafts" do
    assert Listing.new.draft?
  end

  test "requires a title" do
    @listing.title = ""

    assert_not @listing.valid?
    assert_includes @listing.errors[:title], "can't be blank"
  end

  test "monthly rent must be a positive integer" do
    [ 0, -1, 1.5 ].each do |rent|
      @listing.monthly_rent = rent

      assert_not @listing.valid?, "#{rent} should be invalid"
    end
  end

  test "deposit can be zero but not negative" do
    @listing.deposit = 0
    assert @listing.valid?

    @listing.deposit = -1
    assert_not @listing.valid?
  end

  test "minimum stay must be at least one month" do
    @listing.minimum_stay_months = 0

    assert_not @listing.valid?
  end

  test "available_from cannot be in the past on create" do
    listing = @listing.dup
    listing.available_from = Date.yesterday

    assert_not listing.valid?
    assert_includes listing.errors[:available_from], "cannot be in the past"
  end

  test "available_from in the past is allowed on existing listings" do
    @listing.available_from = 1.month.ago.to_date

    assert @listing.valid?
  end

  test "database rejects a non-positive rent" do
    assert_raises(ActiveRecord::StatementInvalid) { @listing.update_columns(monthly_rent: 0) }
  end

  test "published only returns published listings" do
    assert_equal [ listings(:cheap), listings(:pricey) ].sort, Listing.published.sort
  end

  test "under_rent keeps listings at or below the amount" do
    assert_equal [ listings(:cheap) ], Listing.published.under_rent(250_000).to_a
  end

  test "available_by keeps listings available on or before the date" do
    assert_equal [ listings(:cheap) ], Listing.published.available_by(20.days.from_now.to_date).to_a
  end

  test "in_neighborhood filters by the property's neighborhood" do
    assert_equal [ listings(:pricey) ], Listing.published.in_neighborhood(neighborhoods(:nunoa).id).to_a
  end

  test "filter scopes return everything when the value is blank" do
    filtered = Listing.published.in_neighborhood("").under_rent(nil).available_by("")

    assert_equal Listing.published.count, filtered.count
  end

  test "host is the host of the property" do
    assert_equal users(:host), @listing.host
  end
end
