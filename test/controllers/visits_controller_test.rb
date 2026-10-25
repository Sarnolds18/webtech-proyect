require "test_helper"

class VisitsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @application = applications(:shortlisted)
    @visit = visits(:proposed)
  end

  def datetime_param(time)
    time.strftime("%Y-%m-%dT%H:%M")
  end

  test "the host proposes a visit and the seeker confirms it" do
    act_as users(:host)
    get application_path(@application)
    assert_select "form[action='#{application_visits_path(@application)}'] input[type='datetime-local']"

    assert_difference -> { @application.visits.count } do
      post application_visits_path(@application), params: { visit: { scheduled_at: datetime_param(5.days.from_now) } }
    end
    assert_redirected_to application_path(@application)
    visit = @application.visits.order(:created_at).last
    assert visit.proposed?

    act_as users(:seeker)
    get application_path(@application)
    assert_select "form[action='#{confirm_visit_path(visit)}']"
    patch confirm_visit_path(visit)

    assert_redirected_to application_path(@application)
    assert visit.reload.confirmed?
  end

  test "the host reschedules a visit and then marks the new one completed" do
    act_as users(:host)

    assert_difference -> { @application.visits.count } do
      patch reschedule_visit_path(@visit), params: { visit: { scheduled_at: datetime_param(6.days.from_now) } }
    end

    assert_redirected_to application_path(@application)
    assert @visit.reload.cancelled?
    new_visit = @application.visits.proposed.sole

    new_visit.confirm!
    patch complete_visit_path(new_visit)
    assert new_visit.reload.completed?
  end

  test "a visit in the past shows the error next to the field" do
    act_as users(:host)

    assert_no_difference -> { Visit.count } do
      post application_visits_path(@application), params: { visit: { scheduled_at: datetime_param(1.day.ago) } }
    end

    assert_response :unprocessable_entity
    assert_select "#scheduled_at_error", /must be in the future/
  end

  test "a visit for a pending application shows the error in the form" do
    application = applications(:pending)
    act_as users(:host)
    get application_path(application)
    assert_select "form[action='#{application_visits_path(application)}']", count: 0

    post application_visits_path(application), params: { visit: { scheduled_at: datetime_param(5.days.from_now) } }

    assert_response :unprocessable_entity
    assert_select "#application_error", /must be shortlisted/
  end

  test "the host cancels a visit" do
    act_as users(:host)
    patch cancel_visit_path(@visit)

    assert @visit.reload.cancelled?
  end

  test "an invalid transition is explained in the flash" do
    act_as users(:host)
    patch complete_visit_path(@visit)

    assert_redirected_to application_path(@application)
    assert_equal "Status can only be completed once it is confirmed", flash[:alert]
    assert @visit.reload.proposed?
  end

  test "only the seeker confirms and only the host manages visits" do
    act_as users(:host)
    patch confirm_visit_path(@visit)
    assert @visit.reload.proposed?

    act_as users(:seeker)
    patch cancel_visit_path(@visit)
    assert @visit.reload.proposed?
    assert_no_difference -> { Visit.count } do
      post application_visits_path(@application), params: { visit: { scheduled_at: datetime_param(5.days.from_now) } }
    end
    assert_equal "Only the host of the listing can manage its visits.", flash[:alert]
  end
end
