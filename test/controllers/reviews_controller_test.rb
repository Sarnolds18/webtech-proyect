require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @property = properties(:house)
    # The seeker's completed visit, still without a review.
    reviews(:house_review).destroy!
    @visit = visits(:completed)
  end

  test "a seeker with a completed visit reviews the property, and then the form disappears" do
    act_as users(:seeker)
    get property_path(@property)
    assert_select "form[action='#{property_reviews_path(@property)}']" do
      assert_select "input[type=hidden][name='review[visit_id]'][value='#{@visit.id}']"
      assert_select "select#review_rating option", 6
    end

    assert_difference -> { @property.reviews.count } do
      post property_reviews_path(@property), params: { review: { visit_id: @visit.id, rating: 5, comment: "Great house!" } }
    end

    assert_redirected_to property_path(@property)
    follow_redirect!
    assert_select "article", /Great house!/
    assert_select "form[action='#{property_reviews_path(@property)}']", count: 0
  end

  test "an invalid review shows the errors in the form" do
    act_as users(:seeker)

    assert_no_difference -> { Review.count } do
      post property_reviews_path(@property), params: { review: { visit_id: @visit.id, rating: "", comment: "" } }
    end

    assert_response :unprocessable_entity
    assert_select "#comment_error", /can't be blank/
    assert_select "#rating_error"
  end

  test "the host does not see the form and cannot review their own property" do
    act_as users(:host)
    get property_path(@property)
    assert_select "form[action='#{property_reviews_path(@property)}']", count: 0

    assert_no_difference -> { Review.count } do
      post property_reviews_path(@property), params: { review: { visit_id: @visit.id, rating: 5, comment: "Mine!" } }
    end
    assert_response :unprocessable_entity
  end

  test "a visit that is not completed cannot be reviewed" do
    act_as users(:seeker)

    assert_no_difference -> { Review.count } do
      post property_reviews_path(@property), params: { review: { visit_id: visits(:proposed).id, rating: 5, comment: "Hi" } }
    end
    assert_response :unprocessable_entity
  end

  test "a visit to another property is not reviewed from this page" do
    act_as users(:seeker)

    assert_no_difference -> { Review.count } do
      post property_reviews_path(properties(:flat)), params: { review: { visit_id: @visit.id, rating: 5, comment: "Hi" } }
    end
    assert_response :unprocessable_entity
  end
end
