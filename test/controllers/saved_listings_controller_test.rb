require "test_helper"

class SavedListingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @listing = listings(:cheap)
    @seeker = users(:seeker)
  end

  test "a member saves and unsaves a listing from its page, and only the button changes" do
    act_as @seeker
    get listing_path(@listing)
    assert_select "#save_listing_#{@listing.id} button[aria-pressed=false]", /Save/

    assert_difference -> { @seeker.saved_listings.count } do
      post listing_save_path(@listing), as: :turbo_stream
    end
    assert_response :success
    assert_select "turbo-stream[action=replace][target=save_listing_#{@listing.id}]" do
      assert_select "template button[aria-pressed=true]", /Saved/
    end

    assert_difference -> { @seeker.saved_listings.count }, -1 do
      delete listing_save_path(@listing), as: :turbo_stream
    end
    assert_select "turbo-stream[action=replace][target=save_listing_#{@listing.id}] template button[aria-pressed=false]"
  end

  test "saving twice and unsaving something that is not saved change nothing" do
    act_as @seeker
    post listing_save_path(@listing), as: :turbo_stream

    assert_no_difference -> { SavedListing.count } do
      post listing_save_path(@listing), as: :turbo_stream
      assert_response :success
      delete listing_save_path(listings(:pricey)), as: :turbo_stream
      assert_response :success
    end
  end

  test "without Turbo the member goes back to the listing with a notice" do
    act_as @seeker
    post listing_save_path(@listing)
    assert_redirected_to listing_path(@listing)
    follow_redirect!
    assert_select "#flash", /saved/i
    assert_select "#save_listing_#{@listing.id} button[aria-pressed=true]"
  end

  test "a visitor is invited to sign in and cannot save" do
    get listing_path(@listing)
    assert_select "#save_listing_#{@listing.id} a[href='#{new_session_path}']", /Sign in to save/

    assert_no_difference -> { SavedListing.count } do
      post listing_save_path(@listing)
    end
    assert_redirected_to new_session_path
  end

  test "the host sees no button and cannot save their own listing" do
    act_as users(:host)
    get listing_path(@listing)
    assert_select "#save_listing_#{@listing.id} button", count: 0

    assert_no_difference -> { SavedListing.count } do
      post listing_save_path(@listing)
    end
    assert_response :forbidden
  end

  test "somebody else's draft cannot be saved" do
    act_as @seeker

    assert_no_difference -> { SavedListing.count } do
      post listing_save_path(listings(:draft))
    end
    assert_response :forbidden
  end

  test "the saved page lists only the member's own saved listings, with their status" do
    @seeker.saved_listings.create!(listing: @listing)
    users(:other_seeker).saved_listings.create!(listing: listings(:pricey))
    listings(:cheap).withdraw!

    act_as @seeker
    get saved_listings_path
    assert_response :success
    assert_select "a.nav-link[aria-current=page]", "Saved"
    assert_select "#saved_card_listing_#{@listing.id}" do
      assert_select ".badge", /Withdrawn/i
      assert_select "button[aria-pressed=true]"
    end
    assert_select "#saved_card_listing_#{listings(:pricey).id}", count: 0
  end

  test "unsaving on the saved page removes the card and shows the empty state when none are left" do
    @seeker.saved_listings.create!(listing: @listing)
    act_as @seeker

    delete listing_save_path(@listing), as: :turbo_stream
    assert_select "turbo-stream[action=remove][target=saved_card_listing_#{@listing.id}]"
    assert_select "turbo-stream[action=update][target=saved_listings]", /not saved any listings/

    get saved_listings_path
    assert_select "#saved_listings", /not saved any listings/
  end

  test "visitors are sent to sign in from the saved page and do not see the link" do
    get root_path
    assert_select "a.nav-link", text: "Saved", count: 0

    get saved_listings_path
    assert_redirected_to new_session_path
  end
end
