require "test_helper"

class ListingPolicyTest < ActiveSupport::TestCase
  test "a draft is seen only by its host and the moderators" do
    draft = listings(:draft)

    assert_not ListingPolicy.new(nil, draft).show?
    assert_not ListingPolicy.new(users(:seeker), draft).show?
    assert ListingPolicy.new(users(:host), draft).show?
    assert ListingPolicy.new(users(:moderator), draft).show?
  end

  test "everyone sees a published listing" do
    assert ListingPolicy.new(nil, listings(:cheap)).show?
    assert ListingPolicy.new(users(:seeker), listings(:cheap)).show?
  end

  test "only the host creates listings in a property" do
    assert ListingPolicy.new(users(:host), properties(:flat).listings.new).create?
    assert_not ListingPolicy.new(users(:seeker), properties(:flat).listings.new).create?
    assert_not ListingPolicy.new(users(:moderator), properties(:flat).listings.new).create?
    assert_not ListingPolicy.new(nil, properties(:flat).listings.new).create?
  end

  test "the host or a moderator edits, deletes and withdraws; only the host publishes" do
    listing = listings(:cheap)

    %i[update? destroy? withdraw? inbox?].each do |action|
      assert ListingPolicy.new(users(:host), listing).public_send(action), action
      assert ListingPolicy.new(users(:moderator), listing).public_send(action), action
      assert_not ListingPolicy.new(users(:seeker), listing).public_send(action), action
      assert_not ListingPolicy.new(nil, listing).public_send(action), action
    end

    %i[publish? mark_rented?].each do |action|
      assert ListingPolicy.new(users(:host), listing).public_send(action), action
      assert_not ListingPolicy.new(users(:moderator), listing).public_send(action), action
    end
  end

  test "the scope hides other people's drafts" do
    assert_not_includes ListingPolicy::Scope.new(nil, Listing).resolve, listings(:draft)
    assert_not_includes ListingPolicy::Scope.new(users(:seeker), Listing).resolve, listings(:draft)
    assert_includes ListingPolicy::Scope.new(users(:host), Listing).resolve, listings(:draft)
    assert_includes ListingPolicy::Scope.new(users(:moderator), Listing).resolve, listings(:draft)
    assert_includes ListingPolicy::Scope.new(nil, Listing).resolve, listings(:cheap)
  end
end
