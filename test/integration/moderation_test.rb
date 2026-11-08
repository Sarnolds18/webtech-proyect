require "test_helper"

class ModerationFlowTest < ActionDispatch::IntegrationTest
  setup do
    @listing = listings(:cheap)
  end

  test "a member reports somebody else's listing, but not their own" do
    act_as users(:seeker)
    get listing_path(@listing)
    assert_select "summary", /Report this listing/

    assert_difference -> { Report.count } do
      post listing_reports_path(@listing), params: { report: { reason: "misleading", details: "The photos are old." } }
    end
    assert_redirected_to listing_path(@listing)
    follow_redirect!
    assert_select "p", /You reported this listing/

    act_as users(:host)
    get listing_path(@listing)
    assert_select "summary", text: /Report this listing/, count: 0
    assert_no_difference -> { Report.count } do
      post listing_reports_path(@listing), params: { report: { reason: "fraudulent" } }
    end
    assert_response :forbidden
  end

  test "a hand-made report with an unknown reason or on a hidden draft is not saved" do
    act_as users(:seeker)

    assert_no_difference -> { Report.count } do
      post listing_reports_path(@listing), params: { report: { reason: "bogus" } }
      assert_redirected_to listing_path(@listing)
      assert_match "Reason is not included in the list", flash[:alert]

      post listing_reports_path(listings(:draft)), params: { report: { reason: "fraudulent" } }
      assert_response :forbidden
    end
  end

  test "members cannot open or resolve the reports" do
    report = Report.create!(listing: @listing, reporter: users(:seeker), reason: :fraudulent)
    act_as users(:other_seeker)

    get reports_path
    assert_response :forbidden
    get report_path(report)
    assert_response :forbidden
    patch take_action_report_path(report)
    assert_response :forbidden
    assert report.reload.open?
    assert @listing.reload.published?
  end

  test "a moderator dismisses a report and it is logged" do
    report = Report.create!(listing: @listing, reporter: users(:seeker), reason: :offensive)
    act_as users(:moderator)

    get reports_path
    assert_response :success
    assert_select "a[href='#{report_path(report)}']"

    assert_difference -> { ModerationAction.dismiss_report.count } do
      patch dismiss_report_path(report), params: { moderation: { notes: "Nothing offensive." } }
    end
    assert_redirected_to reports_path
    assert report.reload.dismissed?
    assert @listing.reload.published?
    assert_equal "Nothing offensive.", ModerationAction.last.notes
  end

  test "taking action withdraws the listing and closes every open report on it" do
    report = Report.create!(listing: @listing, reporter: users(:seeker), reason: :fraudulent)
    other = Report.create!(listing: @listing, reporter: users(:other_seeker), reason: :misleading)
    act_as users(:moderator)

    assert_difference -> { ModerationAction.withdraw_listing.count } do
      patch take_action_report_path(report)
    end
    assert @listing.reload.withdrawn?
    assert report.reload.action_taken?
    assert other.reload.action_taken?
    assert applications(:pending).reload.rejected?

    patch dismiss_report_path(report)
    assert_redirected_to report_path(report)
    assert_match "already", flash[:alert]
  end

  test "the author deletes their review; another member cannot; a moderator can, and it is logged" do
    review = reviews(:house_review)

    act_as users(:other_seeker)
    delete review_path(review)
    assert_response :forbidden
    assert Review.exists?(review.id)

    act_as users(:moderator)
    get property_path(review.property)
    assert_select "button[aria-label='Delete the review by #{review.author.name}']"
    assert_difference -> { ModerationAction.remove_review.count } do
      delete review_path(review)
    end
    assert_not Review.exists?(review.id)
    assert_match "Lovely garden", ModerationAction.last.notes
  end

  test "the author deletes their own review without a moderation entry" do
    act_as users(:seeker)

    assert_no_difference -> { ModerationAction.count } do
      delete review_path(reviews(:house_review))
    end
    assert_not Review.exists?(reviews(:house_review).id)
  end

  test "the navbar shows the reports with their count only to moderators" do
    Report.create!(listing: @listing, reporter: users(:seeker), reason: :fraudulent)

    act_as users(:seeker)
    get root_path
    assert_select "nav a", text: /Reports/, count: 0
    assert_select "nav a", text: "My applications"

    act_as users(:moderator)
    get root_path
    assert_select "nav a", text: /Reports\s*1/
  end
end
