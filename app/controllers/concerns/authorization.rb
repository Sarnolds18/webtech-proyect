# Pundit in every controller. Hiding a button is a courtesy to the user; these checks are what
# actually block an action, also when somebody types the URL or sends the request by hand.
module Authorization
  extend ActiveSupport::Concern

  included do
    include Pundit::Authorization
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  end

  private

  # Visitors are sent to sign in (`require_user`, from Authentication) and come back afterwards;
  # members get a page that explains what happened, never a raw error.
  def user_not_authorized(exception)
    return require_user unless current_user

    @denied_reason = denied_reason(exception.record)

    if turbo_frame_request?
      render "errors/forbidden_frame", layout: false, status: :forbidden, formats: :html
    elsif request.format.json?
      render json: { error: @denied_reason }, status: :forbidden
    else
      # Also for Turbo form submissions that expect a Turbo Stream: Turbo shows an HTML error
      # response as the new page, so the member lands on the explanation.
      render "errors/forbidden", status: :forbidden, formats: :html
    end
  end

  def denied_reason(record)
    case record
    when Application, Visit
      "Applications are private: only the applicant and the host of the listing can see or answer them."
    when Listing
      record.draft? ? "This listing is a draft. Only its host and the moderators can see it." :
                      "Only the host of this listing can do that."
    when Property
      "Only the host of this property can change it."
    when Review
      "You can review a property only after your own completed visit, and delete only your own reviews."
    when Report, ModerationAction, Neighborhood, Amenity, Class
      "Only moderators can do that."
    else
      "This belongs to another member."
    end
  end
end
