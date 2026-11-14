require "test_helper"

class ReviewRepliesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @review = reviews(:house_review)
    @property = properties(:house)
  end

  test "the host replies to a review from the property page, and the form becomes the reply" do
    act_as users(:host)
    get property_path(@property)
    assert_select "#reply_review_#{@review.id} form[action='#{review_reply_path(@review)}']"

    assert_difference -> { ReviewReply.count } do
      post review_reply_path(@review), params: { review_reply: { comment: "Thank you, come back soon!" } }, as: :turbo_stream
    end
    assert_response :success
    assert_select "turbo-stream[action=replace][target=reply_review_#{@review.id}] template" do
      assert_select "p", /Reply from Valentina Soto/
      assert_select "textarea", count: 0
    end

    get listing_path(listings(:pricey))
    assert_select "#reply_review_#{@review.id}", /Thank you, come back soon!/
  end

  test "an empty reply shows the error in the form" do
    act_as users(:host)

    assert_no_difference -> { ReviewReply.count } do
      post review_reply_path(@review), params: { review_reply: { comment: "" } }, as: :turbo_stream
    end
    assert_response :unprocessable_entity
    assert_select "template #reply_comment_review_#{@review.id}_error", /can't be blank/
  end

  test "a review gets only one reply" do
    @review.create_reply!(author: users(:host), comment: "First answer.")
    act_as users(:host)

    assert_no_difference -> { ReviewReply.count } do
      post review_reply_path(@review), params: { review_reply: { comment: "Second answer." } }, as: :turbo_stream
    end
    assert_equal "First answer.", @review.reload.reply.comment
  end

  test "nobody but the host sees the form or can reply" do
    [ users(:seeker), users(:other_seeker), users(:moderator) ].each do |user|
      act_as user
      get property_path(@property)
      assert_select "#reply_review_#{@review.id} form", count: 0

      assert_no_difference -> { ReviewReply.count } do
        post review_reply_path(@review), params: { review_reply: { comment: "Not mine to answer." } }
      end
      assert_response :forbidden
    end
  end

  test "a visitor is sent to sign in" do
    post review_reply_path(@review), params: { review_reply: { comment: "Hello" } }
    assert_redirected_to new_session_path
  end

  test "the host deletes their own reply without a moderation log" do
    @review.create_reply!(author: users(:host), comment: "Thanks!")
    act_as users(:host)

    assert_no_difference -> { ModerationAction.count } do
      delete review_reply_path(@review), as: :turbo_stream
    end
    assert_nil @review.reload.reply
    assert_select "turbo-stream[action=replace][target=reply_review_#{@review.id}] template form"
  end

  test "a moderator deletes a reply and the deletion is logged" do
    @review.create_reply!(author: users(:host), comment: "Rude answer.")
    act_as users(:moderator)

    assert_difference -> { ModerationAction.count } do
      delete review_reply_path(@review)
    end
    assert_nil @review.reload.reply
    log = ModerationAction.last
    assert_predicate log, :remove_review?
    assert_equal users(:host), log.target_user
    assert_match "Rude answer.", log.notes
  end

  test "other members cannot delete the reply" do
    @review.create_reply!(author: users(:host), comment: "Thanks!")
    act_as users(:seeker)

    delete review_reply_path(@review)
    assert_response :forbidden
    assert_not_nil @review.reload.reply
  end
end
