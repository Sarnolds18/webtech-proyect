require "test_helper"

class InboxesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @listing = listings(:cheap)
    password = "password123"
    # Three applications waiting for an answer.
    @applications = [ applications(:pending) ] + [
      User.create!(name: "Tomás Fuentes", email_address: "tomas.fuentes@roomies.test", password:),
      User.create!(name: "Isidora Pérez", email_address: "isidora.perez@roomies.test", password:)
    ].map do |seeker|
      @listing.applications.create!(seeker:, message: "Hello!", move_in_date: 15.days.from_now.to_date, stay_months: 6)
    end
  end

  test "the host reads the inbox with the pending counter" do
    act_as users(:host)
    get listing_inbox_path(@listing)

    assert_response :success
    assert_select "#pending_count", "3"
    @applications.each { |application| assert_select "tr##{dom_id(application)}" }
  end

  test "only the host opens the inbox" do
    act_as users(:seeker)
    get listing_inbox_path(@listing)

    assert_redirected_to listing_path(@listing)
    assert_equal "Only the host of this listing can open its inbox.", flash[:alert]
  end

  test "the property page links the host to the inbox of each listing" do
    act_as users(:host)
    get property_path(properties(:flat))

    assert_select "a[href='#{listing_inbox_path(@listing)}']"
  end

  test "shortlisting replaces the row, the counter and the flash" do
    act_as users(:host)
    application = @applications.first

    patch shortlist_application_path(application), as: :turbo_stream

    assert_response :success
    assert_equal Mime[:turbo_stream], response.media_type
    assert application.reload.shortlisted?
    assert_select "turbo-stream[action=replace][target=#{dom_id(application)}]"
    assert_select "turbo-stream[action=update][target=pending_count] template", "2"
    assert_select "turbo-stream[action=replace][target=flash] template", /is on the shortlist/
  end

  test "rejecting replaces the row" do
    act_as users(:host)
    application = @applications.first

    patch reject_application_path(application), as: :turbo_stream

    assert application.reload.rejected?
    assert_select "turbo-stream[action=replace][target=#{dom_id(application)}]"
    assert_select "turbo-stream[action=update][target=pending_count] template", "2"
  end

  test "accepting one application replaces every row and the counter goes down to zero" do
    act_as users(:host)
    accepted = @applications.first

    patch accept_application_path(accepted), as: :turbo_stream

    assert_response :success
    assert accepted.reload.accepted?
    assert @listing.reload.reserved?
    @applications.drop(1).each do |application|
      assert application.reload.rejected?
      assert_select "turbo-stream[action=replace][target=#{dom_id(application)}] template", /Rejected/
    end
    assert_select "turbo-stream[action=update][target=pending_count] template", "0"
    assert_select "turbo-stream[action=replace][target=flash] template", /The listing is now reserved/
  end

  test "an answer the model refuses only updates the flash" do
    act_as users(:host)
    application = @applications.first
    application.update!(status: :rejected)

    patch accept_application_path(application), as: :turbo_stream

    assert_response :unprocessable_entity
    assert_select "turbo-stream[action=replace][target=flash] template", /cannot be accepted once it is rejected/
    assert_select "turbo-stream[target=#{dom_id(application)}]", count: 0
  end

  test "without Turbo the answer redirects to the inbox" do
    act_as users(:host)

    patch shortlist_application_path(@applications.first)

    assert_redirected_to listing_inbox_path(@listing)
  end

  test "only the host answers applications" do
    act_as users(:other_seeker)
    application = @applications.first

    patch accept_application_path(application), as: :turbo_stream

    assert_redirected_to listing_path(@listing)
    assert application.reload.pending?
  end
end
