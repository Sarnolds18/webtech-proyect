# The host of a property answers each review of it once (ReviewReplyPolicy; the model also checks it).
# The reply's author or a moderator deletes it; a moderator's deletion is logged. Both actions answer
# with a Turbo Stream that replaces only the reply area of that review.
class ReviewRepliesController < ApplicationController
  before_action :require_user
  before_action :set_review
  after_action :verify_authorized

  # Built with `ReviewReply.new` and not `@review.build_reply`: building a has_one deletes the
  # existing reply, and a second reply must fail validation instead.
  def create
    reply = authorize ReviewReply.new(review: @review, author: current_user, comment: params.expect(review_reply: [ :comment ])[:comment])

    if reply.save
      @review.reload
      respond_with_reply notice: "Your reply was published."
    else
      respond_with_reply reply_form: reply, status: :unprocessable_entity, alert: reply.errors.full_messages.to_sentence
    end
  end

  # The reply row is deleted, so a moderator's log entry keeps what it said in its notes.
  def destroy
    reply = authorize @review.reply || raise(ActiveRecord::RecordNotFound)

    ReviewReply.transaction do
      reply.destroy!
      unless reply.author == current_user
        ModerationAction.create!(moderator: current_user, action_type: :remove_review, target_user: reply.author,
                                 notes: "Removed the host's reply to a review of #{@review.property.title}: " \
                                        "#{reply.comment.truncate(100)}")
      end
    end

    @review.reload
    respond_with_reply notice: "The reply was deleted."
  end

  private

  def set_review
    @review = Review.includes(:property, reply: :author).find(params[:review_id])
  end

  def respond_with_reply(status: :ok, reply_form: nil, notice: nil, alert: nil)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(helpers.dom_id(@review, :reply), partial: "reviews/reply",
                                                                                   locals: { review: @review, reply_form: reply_form }),
               status: status
      end
      format.html { redirect_back_or_to @review.property, notice: notice, alert: alert }
    end
  end
end
