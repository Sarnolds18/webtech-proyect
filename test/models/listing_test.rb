require "test_helper"

class ListingTest < ActiveSupport::TestCase
  setup do
    @listing = listings(:cheap)
  end

  # An attachable for a file in test/fixtures/files, like the ones a form upload produces.
  def upload(name, content_type)
    { io: file_fixture(name).open, filename: name, content_type: content_type }
  end

  test "fixture is valid" do
    assert @listing.valid?
  end

  test "new listings start as drafts" do
    assert Listing.new.draft?
  end

  test "requires a title" do
    @listing.title = ""

    assert_not @listing.valid?
    assert_includes @listing.errors[:title], "can't be blank"
  end

  test "monthly rent must be a positive integer" do
    [ 0, -1, 1.5 ].each do |rent|
      @listing.monthly_rent = rent

      assert_not @listing.valid?, "#{rent} should be invalid"
    end
  end

  test "deposit can be zero but not negative" do
    @listing.deposit = 0
    assert @listing.valid?

    @listing.deposit = -1
    assert_not @listing.valid?
  end

  test "minimum stay must be at least one month" do
    @listing.minimum_stay_months = 0

    assert_not @listing.valid?
  end

  test "available_from cannot be in the past on create" do
    listing = @listing.dup
    listing.available_from = Date.yesterday

    assert_not listing.valid?
    assert_includes listing.errors[:available_from], "cannot be in the past"
  end

  test "available_from in the past is allowed on existing listings" do
    @listing.available_from = 1.month.ago.to_date

    assert @listing.valid?
  end

  test "database rejects a non-positive rent" do
    assert_raises(ActiveRecord::StatementInvalid) { @listing.update_columns(monthly_rent: 0) }
  end

  test "published only returns published listings" do
    assert_equal [ listings(:cheap), listings(:pricey) ].sort, Listing.published.sort
  end

  test "under_rent keeps listings at or below the amount" do
    assert_equal [ listings(:cheap) ], Listing.published.under_rent(250_000).to_a
  end

  test "available_by keeps listings available on or before the date" do
    assert_equal [ listings(:cheap) ], Listing.published.available_by(20.days.from_now.to_date).to_a
  end

  test "in_neighborhood filters by the property's neighborhood" do
    assert_equal [ listings(:pricey) ], Listing.published.in_neighborhood(neighborhoods(:nunoa).id).to_a
  end

  test "filter scopes return everything when the value is blank" do
    filtered = Listing.published.in_neighborhood("").under_rent(nil).available_by("")

    assert_equal Listing.published.count, filtered.count
  end

  test "host is the host of the property" do
    assert_equal users(:host), @listing.host
  end

  test "accepts several photographs" do
    2.times { @listing.photos.attach(upload("room.jpg", "image/jpeg")) }

    assert @listing.valid?
    assert_equal 2, @listing.photos.size
  end

  test "rejects files that are not images" do
    @listing.photos.attach(upload("notes.txt", "text/plain"))

    assert_not @listing.valid?
    assert_includes @listing.errors[:photos], "notes.txt is not a JPEG, PNG or WebP image"
  end

  test "rejects photographs over the size limit" do
    big = StringIO.new("0" * (Listing::MAX_PHOTO_SIZE + 1))
    @listing.photos.attach(io: big, filename: "huge.jpg", content_type: "image/jpeg", identify: false)

    assert_not @listing.valid?
    assert_includes @listing.errors[:photos], "huge.jpg is larger than 5 MB"
  end

  test "rejects more photographs than the limit" do
    (Listing::MAX_PHOTOS + 1).times { @listing.photos.attach(upload("room.jpg", "image/jpeg")) }

    assert_not @listing.valid?
    assert_includes @listing.errors[:photos], "can be at most #{Listing::MAX_PHOTOS}"
  end

  test "the form keeps saved photographs by sending back their signed ids" do
    @listing.photos.attach(upload("room.jpg", "image/jpeg"))
    kept = @listing.photos.first

    # What listings/_photo_fields submits: the saved photographs' signed ids, a blank, and the new file.
    @listing.update!(photos: [ kept.signed_id, "", upload("room.jpg", "image/jpeg") ])

    assert_equal 2, @listing.reload.photos.size
    assert_includes @listing.photos.map(&:blob_id), kept.blob_id
  end

  test "cards use a small variant instead of the full photograph" do
    @listing.photos.attach(upload("room.jpg", "image/jpeg"))
    @listing.save!

    card = @listing.photos.first.variant(:card).processed
    image = card.image.blob.open { |file| Vips::Image.new_from_file(file.path) }

    assert_equal [ 600, 400 ], [ image.width, image.height ]
  end

  test "description and house rules keep their formatting as rich text" do
    @listing.update!(description: "A <strong>bright</strong> room", house_rules: "<ul><li>No smoking</li></ul>")

    assert_includes @listing.reload.description.body.to_html, "<strong>bright</strong>"
    assert_equal "No smoking", @listing.house_rules.to_plain_text.strip.delete_prefix("• ")
  end

  test "a draft is visible only to its host" do
    draft = listings(:draft)

    assert draft.visible_to?(users(:host))
    assert_not draft.visible_to?(users(:seeker))
    assert_not draft.visible_to?(nil)
    assert @listing.visible_to?(nil)
  end

  test "a draft is published" do
    draft = listings(:draft)
    draft.publish!

    assert draft.reload.published?
  end

  test "only a draft can be published" do
    error = assert_raises(ActiveRecord::RecordInvalid) { @listing.publish! }

    assert_match "can only be published while it is a draft", error.message
  end

  test "withdrawing rejects the pending and shortlisted applications, and only those" do
    shortlisted = Application.create!(listing: @listing, seeker: users(:other_seeker), status: :shortlisted,
                                      message: "Count me in.", move_in_date: 20.days.from_now.to_date, stay_months: 6)
    accepted = Application.create!(listing: @listing, seeker: users(:moderator), status: :accepted,
                                   message: "Me too.", move_in_date: 20.days.from_now.to_date, stay_months: 6)
    @listing.withdraw!

    assert @listing.reload.withdrawn?
    assert applications(:pending).reload.rejected?
    assert shortlisted.reload.rejected?
    assert accepted.reload.accepted?
  end

  test "a reserved listing can be withdrawn" do
    @listing.update!(status: :reserved)
    @listing.withdraw!

    assert @listing.reload.withdrawn?
  end

  test "drafts, rented and withdrawn listings cannot be withdrawn" do
    assert_raises(ActiveRecord::RecordInvalid) { listings(:draft).withdraw! }
    assert listings(:draft).reload.draft?

    %i[rented withdrawn].each do |status|
      @listing.update!(status: status)

      assert_raises(ActiveRecord::RecordInvalid) { @listing.withdraw! }
      assert_equal status.to_s, @listing.reload.status
    end
    assert applications(:pending).reload.pending?
  end

  test "only a reserved listing is marked as rented" do
    assert_raises(ActiveRecord::RecordInvalid) { @listing.mark_rented! }

    @listing.update!(status: :reserved)
    @listing.mark_rented!

    assert @listing.reload.rented?
  end

  test "only a draft can be deleted" do
    assert_not @listing.destroy
    assert_includes @listing.errors[:base], "Only a draft can be deleted. Withdraw the listing instead."
    assert Listing.exists?(@listing.id)

    assert listings(:draft).destroy
  end
end
