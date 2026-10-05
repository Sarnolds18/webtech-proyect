require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  setup do
    @review = reviews(:house_review)
  end

  test "fixture is valid" do
    assert @review.valid?
  end

  test "rating must be between 1 and 5" do
    [ 0, 6 ].each do |rating|
      @review.rating = rating

      assert_not @review.valid?, "#{rating} should be invalid"
    end
  end

  test "database rejects a rating outside 1 to 5" do
    assert_raises(ActiveRecord::StatementInvalid) { @review.update_columns(rating: 6) }
  end

  test "only one review per visit" do
    review = Review.new(visit: visits(:completed), author: users(:seeker), rating: 5, comment: "Again!")

    assert_not review.valid?
    assert_includes review.errors[:visit_id], "already has a review"
  end

  test "the visit must be completed" do
    review = Review.new(visit: visits(:proposed), author: users(:seeker), rating: 5, comment: "Nice")

    assert_not review.valid?
    assert_includes review.errors[:visit], "must be completed before it can be reviewed"
  end

  test "property is taken from the visit" do
    @review.destroy!
    review = Review.create!(visit: visits(:completed), author: users(:seeker), rating: 5, comment: "Great")

    assert_equal properties(:house), review.property
  end

  test "the author must be the seeker who made the visit" do
    @review.destroy!
    review = Review.new(visit: visits(:completed), author: users(:host), rating: 5, comment: "My own house")

    assert_not review.valid?
    assert_includes review.errors[:author], "must be the seeker who made the visit"
    assert_includes review.errors[:author], "cannot review their own property"
  end

  test "only the host can reply" do
    assert ReviewReply.new(review: @review, author: users(:host), comment: "Thank you!").valid?

    reply = ReviewReply.new(review: @review, author: users(:other_seeker), comment: "Hi")
    assert_not reply.valid?
    assert_includes reply.errors[:author], "must be the host of the reviewed property"
  end
end
