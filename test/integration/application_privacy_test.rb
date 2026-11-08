require "test_helper"

# Applications must not be reachable by guessing their id, and every answer is blocked in the
# controller, not only hidden in the page.
class ApplicationPrivacyTest < ActionDispatch::IntegrationTest
  setup do
    @application = applications(:pending)
  end

  test "visitors are sent to sign in" do
    get applications_path
    assert_redirected_to new_session_path

    get application_path(@application)
    assert_redirected_to new_session_path
  end

  test "another member cannot open an application by its id, nor find it in their list" do
    act_as users(:other_seeker)

    get application_path(@application)
    assert_response :forbidden
    assert_select "h1", "Access denied"
    assert_no_match @application.message, response.body

    get applications_path
    assert_response :success
    assert_no_match @application.message, response.body
    assert_select "a[href='#{application_path(@application)}']", count: 0
  end

  test "the seeker sees what they sent and the host what they received" do
    act_as users(:seeker)
    get applications_path
    assert_select "#sent-heading", /Applications I sent/
    assert_select "a[href='#{application_path(@application)}']"

    act_as users(:host)
    get applications_path
    assert_select "#received-heading"
    assert_select "a[href='#{listing_inbox_path(@application.listing)}']"
    get application_path(@application)
    assert_response :success
    assert_select "dd", @application.seeker.email_address
  end

  test "the seeker does not see contact details meant for the host" do
    act_as users(:seeker)
    get application_path(@application)
    assert_response :success
    assert_select "dt", text: "Email", count: 0
  end

  test "a member cannot accept somebody else's application by sending the request" do
    act_as users(:other_seeker)
    patch accept_application_path(@application), as: :turbo_stream

    assert_response :forbidden
    assert @application.reload.pending?
  end

  test "a moderator reads any application but cannot answer it" do
    act_as users(:moderator)

    get application_path(@application)
    assert_response :success
    get applications_path
    assert_select "#others-heading"

    get listing_inbox_path(@application.listing)
    assert_response :success
    assert_select "button", text: "Accept", count: 0

    patch accept_application_path(@application), as: :turbo_stream
    assert_response :forbidden
    assert @application.reload.pending?
  end

  test "applying to your own listing is denied inside the Turbo Frame" do
    act_as users(:host)

    assert_no_difference -> { Application.count } do
      post listing_applications_path(listings(:cheap)),
           params: { application: { message: "Me", move_in_date: 20.days.from_now.to_date, stay_months: 6 } },
           headers: { "Turbo-Frame" => "application_block" }
    end
    assert_response :forbidden
    assert_select "turbo-frame#application_block", /Access denied/
  end

  test "the applicant cancels their visit; somebody else cannot" do
    visit = visits(:proposed)

    act_as users(:other_seeker)
    patch cancel_visit_path(visit)
    assert_response :forbidden
    assert visit.reload.proposed?

    act_as users(:seeker)
    patch cancel_visit_path(visit)
    assert visit.reload.cancelled?
  end
end
