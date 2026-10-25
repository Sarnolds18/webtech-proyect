require "test_helper"

class ApplicationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @listing = listings(:pricey)
  end

  def application_params(**overrides)
    { message: "I am tidy and I would love to visit the room.", move_in_date: 45.days.from_now.to_date,
      stay_months: 12 }.merge(overrides)
  end

  def turbo_frame_headers
    { "Turbo-Frame" => "application_block" }
  end

  test "visitors are asked to choose a user on the listing page" do
    get listing_path(@listing)

    assert_select "turbo-frame#application_block", /Choose a user in the navbar/
    assert_select "turbo-frame#application_block form", count: 0
  end

  test "the host sees a link to the inbox instead of the form" do
    act_as users(:host)
    get listing_path(@listing)

    assert_select "turbo-frame#application_block", /This is your listing/
    assert_select "turbo-frame#application_block a[href='#{listing_inbox_path(@listing)}']"
  end

  test "a listing that is not published does not take applications" do
    @listing.update!(status: :withdrawn)
    act_as users(:other_seeker)
    get listing_path(@listing)

    assert_select "turbo-frame#application_block", /Not accepting applications/
  end

  test "a seeker applies from the listing page and gets back only the block" do
    act_as users(:other_seeker)
    get listing_path(@listing)
    assert_select "turbo-frame#application_block form[action='#{listing_applications_path(@listing)}']" do
      assert_select "textarea#application_message"
      assert_select "input[type=date]#application_move_in_date"
      assert_select "input[type=number][min='12']#application_stay_months"
    end

    assert_difference -> { @listing.applications.count } do
      post listing_applications_path(@listing), params: { application: application_params }, headers: turbo_frame_headers
    end

    assert_response :success
    assert_select "turbo-frame#application_block", /Your application was sent/
    assert_select "nav", count: 0, message: "the response is the block, not the whole page"
    application = @listing.applications.find_by!(seeker: users(:other_seeker))
    assert application.pending?
    assert_select "form[action='#{withdraw_application_path(application)}']"
  end

  test "an empty application shows the errors inside the block" do
    act_as users(:other_seeker)

    assert_no_difference -> { Application.count } do
      post listing_applications_path(@listing), params: { application: application_params(message: "", stay_months: 0) },
                                                headers: turbo_frame_headers
    end

    assert_response :unprocessable_entity
    assert_select "turbo-frame#application_block" do
      assert_select "#message_error", /can't be blank/
      assert_select "#stay_months_error"
    end
  end

  test "applying twice shows the error inside the block" do
    act_as users(:seeker)

    assert_no_difference -> { Application.count } do
      post listing_applications_path(@listing), params: { application: application_params }, headers: turbo_frame_headers
    end

    assert_response :unprocessable_entity
    assert_select "turbo-frame#application_block #seeker_id_error", /already applied/
  end

  test "visitors cannot apply" do
    assert_no_difference -> { Application.count } do
      post listing_applications_path(@listing), params: { application: application_params }
    end

    assert_equal "Choose a user in the navbar first.", flash[:alert]
  end

  test "the seeker withdraws their application" do
    application = applications(:shortlisted)
    act_as users(:seeker)

    patch withdraw_application_path(application), headers: turbo_frame_headers

    assert_response :success
    assert application.reload.withdrawn?
    assert_select "turbo-frame#application_block", /You withdrew your application/
    assert_select "form[action='#{withdraw_application_path(application)}']", count: 0
  end

  test "an answered application cannot be withdrawn" do
    application = applications(:shortlisted)
    application.update!(status: :rejected)
    act_as users(:seeker)

    patch withdraw_application_path(application), headers: turbo_frame_headers

    assert_response :unprocessable_entity
    assert_select "turbo-frame#application_block", /cannot be withdrawn once it is rejected/
  end

  test "only the seeker withdraws an application" do
    application = applications(:shortlisted)
    act_as users(:other_seeker)

    patch withdraw_application_path(application)

    assert_redirected_to listing_path(@listing)
    assert application.reload.shortlisted?
  end
end
