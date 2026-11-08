require "test_helper"

# The rest of the permission table of the assignment, one policy at a time.
class OtherPoliciesTest < ActiveSupport::TestCase
  test "properties: any member creates; the host or a moderator changes them" do
    property = properties(:flat)

    assert PropertyPolicy.new(nil, property).show?
    assert_not PropertyPolicy.new(nil, Property.new).create?
    assert PropertyPolicy.new(users(:seeker), Property.new).create?
    assert PropertyPolicy.new(users(:host), property).update?
    assert PropertyPolicy.new(users(:moderator), property).destroy?
    assert_not PropertyPolicy.new(users(:seeker), property).update?
  end

  test "visits: the host proposes and completes, the applicant confirms, either cancels" do
    visit = visits(:proposed)

    assert VisitPolicy.new(users(:host), visit).create?
    assert_not VisitPolicy.new(users(:seeker), visit).create?
    assert VisitPolicy.new(users(:seeker), visit).confirm?
    assert_not VisitPolicy.new(users(:host), visit).confirm?
    assert VisitPolicy.new(users(:host), visit).cancel?
    assert VisitPolicy.new(users(:seeker), visit).cancel?
    assert_not VisitPolicy.new(users(:other_seeker), visit).cancel?
    assert_not VisitPolicy.new(users(:moderator), visit).cancel?
    assert_not VisitPolicy.new(users(:seeker), visit).complete?
  end

  test "reviews: only about your own completed visit; deleted by the author or a moderator" do
    completed = visits(:completed)
    review = reviews(:house_review)

    assert ReviewPolicy.new(users(:seeker), Review.new(visit: completed)).create?
    assert_not ReviewPolicy.new(users(:other_seeker), Review.new(visit: completed)).create?
    assert_not ReviewPolicy.new(users(:seeker), Review.new(visit: visits(:proposed))).create?
    assert_not ReviewPolicy.new(nil, Review.new(visit: completed)).create?

    assert ReviewPolicy.new(users(:seeker), review).destroy?
    assert ReviewPolicy.new(users(:moderator), review).destroy?
    assert_not ReviewPolicy.new(users(:host), review).destroy?
  end

  test "reports: members report other people's listings; only moderators resolve them" do
    report = Report.new(listing: listings(:cheap), reporter: users(:seeker))

    assert ReportPolicy.new(users(:seeker), report).create?
    assert ReportPolicy.new(users(:moderator), report).create?
    assert_not ReportPolicy.new(users(:host), Report.new(listing: listings(:cheap))).create?
    assert_not ReportPolicy.new(nil, report).create?
    assert_not ReportPolicy.new(users(:seeker), Report.new(listing: listings(:draft))).create?

    assert ReportPolicy.new(users(:moderator), report).take_action?
    assert_not ReportPolicy.new(users(:seeker), report).dismiss?
    assert_not ReportPolicy.new(users(:seeker), Report).index?
    assert_empty ReportPolicy::Scope.new(users(:seeker), Report).resolve
  end

  test "catalogs: only moderators manage neighborhoods and amenities" do
    [ NeighborhoodPolicy.new(nil, neighborhoods(:nunoa)), AmenityPolicy.new(nil, amenities(:wifi)) ].each do |policy|
      assert policy.show?
      assert_not policy.update?
    end

    assert_not NeighborhoodPolicy.new(users(:seeker), Neighborhood).create?
    assert NeighborhoodPolicy.new(users(:moderator), Neighborhood).create?
    assert_not AmenityPolicy.new(users(:host), amenities(:wifi)).destroy?
    assert AmenityPolicy.new(users(:moderator), amenities(:wifi)).destroy?
  end

  test "moderation log, saved listings, amenities of a property and accounts" do
    assert ModerationActionPolicy.new(users(:moderator), ModerationAction).index?
    assert_not ModerationActionPolicy.new(users(:seeker), ModerationAction).index?

    saved = SavedListing.new(user: users(:seeker), listing: listings(:cheap))
    assert SavedListingPolicy.new(users(:seeker), saved).destroy?
    assert_not SavedListingPolicy.new(users(:other_seeker), saved).destroy?

    assert PropertyAmenityPolicy.new(users(:host), PropertyAmenity.new(property: properties(:flat))).create?
    assert_not PropertyAmenityPolicy.new(users(:seeker), PropertyAmenity.new(property: properties(:flat))).create?

    assert UserPolicy.new(users(:seeker), users(:seeker)).update?
    assert_not UserPolicy.new(users(:seeker), users(:host)).show?
  end
end
