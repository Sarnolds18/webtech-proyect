require "test_helper"

class ListingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @property = properties(:flat)
    @draft = listings(:draft)
  end

  def listing_params(**overrides)
    { title: "Room with a view of the Andes", monthly_rent: 300_000, deposit: 300_000,
      available_from: 7.days.from_now.to_date, minimum_stay_months: 6, furnished: "1", private_bathroom: "0",
      description: "<div>A <strong>bright</strong> room.</div>", house_rules: "<ul><li>No smoking</li></ul>" }.merge(overrides)
  end

  test "the host creates a listing inside a property, as a draft" do
    act_as users(:host)
    get new_property_listing_path(@property)
    assert_response :success
    assert_select "form[action='#{property_listings_path(@property)}']"
    assert_select "input[type=number]#listing_monthly_rent"
    assert_select "input[type=date]#listing_available_from"

    assert_difference -> { @property.listings.count } do
      post property_listings_path(@property), params: {
        listing: listing_params(photos: [ fixture_file_upload("room.jpg", "image/jpeg") ])
      }
    end

    listing = Listing.last
    assert_redirected_to listing_path(listing)
    assert listing.draft?
    assert listing.furnished?
    assert_equal 1, listing.photos.count
    assert_includes listing.description.body.to_html, "<strong>bright</strong>"
  end

  test "editing the rent through the form keeps the photos" do
    @draft.photos.attach(io: file_fixture("room.jpg").open, filename: "room.jpg", content_type: "image/jpeg")
    act_as users(:host)
    get edit_listing_path(@draft)
    signed_ids = css_select("input[type=hidden][name='listing[photos][]']").map { |input| input["value"] }.compact_blank
    assert_equal 1, signed_ids.size

    patch listing_path(@draft), params: { listing: { monthly_rent: 215_000, photos: [ "", *signed_ids ] } }

    assert_redirected_to listing_path(@draft)
    assert_equal 215_000, @draft.reload.monthly_rent
    assert_equal 1, @draft.photos.count
  end

  test "a file that is not an image shows the error next to the photos field" do
    act_as users(:host)
    post property_listings_path(@property), params: {
      listing: listing_params(photos: [ fixture_file_upload("notes.txt", "text/plain") ])
    }

    assert_response :unprocessable_entity
    assert_select "#photos_error", /notes.txt is not a JPEG, PNG or WebP image/
  end

  test "the status cannot be set from the form" do
    act_as users(:host)
    post property_listings_path(@property), params: { listing: listing_params(status: "published") }

    assert Listing.last.draft?
  end

  test "invalid listings render the form again with the errors next to each field" do
    act_as users(:host)

    assert_no_difference -> { Listing.count } do
      post property_listings_path(@property), params: { listing: listing_params(monthly_rent: 0, available_from: Date.yesterday) }
    end

    assert_response :unprocessable_entity
    assert_select "#listing_monthly_rent.is-invalid"
    assert_select "#available_from_error", /cannot be in the past/
  end

  test "only the host adds listings to a property" do
    act_as users(:seeker)

    assert_no_difference -> { Listing.count } do
      post property_listings_path(@property), params: { listing: listing_params }
    end
    assert_redirected_to property_path(@property)
  end

  test "a draft redirects everyone but its host" do
    get listing_path(@draft)
    assert_redirected_to listings_path
    assert_equal "That listing is not available.", flash[:alert]

    act_as users(:seeker)
    get listing_path(@draft)
    assert_redirected_to listings_path

    act_as users(:host)
    get listing_path(@draft)
    assert_response :success
    assert_select "#status-actions-heading", /Your listing/
    assert_select "button", text: "Publish"
    assert_select "button", text: "Delete"
    assert_select "button", text: "Withdraw", count: 0
  end

  test "a draft is not in the index until it is published" do
    get listings_path
    assert_select "a", text: @draft.title, count: 0

    @draft.publish!
    get listings_path
    assert_select "a", text: @draft.title
  end

  test "visitors and members do not see the status actions" do
    get listing_path(listings(:cheap))
    assert_select "#status-actions-heading", count: 0

    act_as users(:seeker)
    get listing_path(listings(:cheap))
    assert_select "#status-actions-heading", count: 0
  end

  test "the host updates a listing" do
    act_as users(:host)
    patch listing_path(@draft), params: { listing: { monthly_rent: 210_000 } }

    assert_redirected_to listing_path(@draft)
    assert_equal 210_000, @draft.reload.monthly_rent
  end

  test "the host publishes a draft, and the actions change with its state" do
    act_as users(:host)
    patch publish_listing_path(@draft)

    assert_redirected_to listing_path(@draft)
    assert @draft.reload.published?
    follow_redirect!
    assert_select "button", text: "Publish", count: 0
    assert_select "button", text: "Delete", count: 0
    assert_select "button", text: "Withdraw"
  end

  test "publishing twice is refused with a flash message" do
    act_as users(:host)
    patch publish_listing_path(listings(:cheap))

    assert_redirected_to listing_path(listings(:cheap))
    assert_match "can only be published while it is a draft", flash[:alert]
  end

  test "withdrawing a listing rejects its pending applications" do
    act_as users(:host)
    patch withdraw_listing_path(listings(:cheap))

    assert listings(:cheap).reload.withdrawn?
    assert applications(:pending).reload.rejected?
  end

  test "a reserved listing is marked as rented" do
    listing = listings(:cheap)
    listing.update!(status: :reserved)
    act_as users(:host)
    get listing_path(listing)
    assert_select "button", text: "Mark as rented"
    assert_select "button", text: "Withdraw"

    patch mark_rented_listing_path(listing)
    assert listing.reload.rented?
  end

  test "only the host moves a listing through its lifecycle" do
    act_as users(:seeker)
    patch withdraw_listing_path(listings(:cheap))
    assert listings(:cheap).reload.published?
    assert_redirected_to listing_path(listings(:cheap))

    act_as users(:moderator)
    patch publish_listing_path(@draft)
    assert @draft.reload.draft?
  end

  test "a moderator withdraws a listing" do
    act_as users(:moderator)
    get listing_path(listings(:cheap))
    assert_select "#status-actions-heading", /Moderation/
    assert_select "button", text: "Withdraw"
    assert_select "a", text: "Edit listing", count: 0

    patch withdraw_listing_path(listings(:cheap))
    assert listings(:cheap).reload.withdrawn?
  end

  test "the host deletes a listing without applications" do
    act_as users(:host)

    assert_difference -> { Listing.count }, -1 do
      delete listing_path(@draft)
    end
    assert_redirected_to property_path(@property)
  end

  test "a published listing is not deleted" do
    act_as users(:host)

    assert_no_difference -> { Listing.count } do
      delete listing_path(listings(:cheap))
    end
    assert_equal "Only a draft can be deleted. Withdraw the listing instead.", flash[:alert]
  end
end
