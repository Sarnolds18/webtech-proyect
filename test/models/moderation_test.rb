require "test_helper"

# Saved listings, reports and moderation actions.
class ModerationTest < ActiveSupport::TestCase
  test "a listing can be saved only once per user" do
    SavedListing.create!(user: users(:seeker), listing: listings(:cheap))

    assert_not SavedListing.new(user: users(:seeker), listing: listings(:cheap)).valid?
  end

  test "a member reports a listing once and never their own" do
    Report.create!(listing: listings(:cheap), reporter: users(:seeker), reason: :misleading)

    assert_not Report.new(listing: listings(:cheap), reporter: users(:seeker), reason: :fraudulent).valid?

    own = Report.new(listing: listings(:cheap), reporter: users(:host), reason: :offensive)
    assert_not own.valid?
    assert_includes own.errors[:reporter], "cannot report their own listing"
  end

  test "new reports are open and unresolved" do
    report = Report.create!(listing: listings(:cheap), reporter: users(:seeker), reason: :fraudulent)

    assert report.open?
    assert_includes Report.unresolved, report
  end

  test "only moderators record moderation actions" do
    assert ModerationAction.new(moderator: users(:moderator), action_type: :withdraw_listing,
                                target_listing: listings(:cheap)).valid?

    action = ModerationAction.new(moderator: users(:seeker), action_type: :suspend_user, target_user: users(:host))
    assert_not action.valid?
    assert_includes action.errors[:moderator], "must have the moderator role"
  end
end
