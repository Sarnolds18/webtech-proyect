class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user

  private

  # The user chosen in the navbar selector, or nil for a visitor. Assignment 4 replaces the
  # selector with real authentication, keeping this method's name.
  def current_user
    return @current_user if defined?(@current_user)

    @current_user = User.find_by(id: session[:acting_user_id])
  end

  # Simple permission checks until Assignment 4 brings Pundit.

  # For actions that need an author, e.g. creating a property: visitors are asked to pick a user.
  def require_user
    redirect_back_or_to root_path, alert: "Choose a user in the navbar first." unless current_user
  end

  # For the catalogs (neighborhoods and amenities).
  def require_moderator
    redirect_back_or_to root_path, alert: "Only moderators can do that." unless current_user&.moderator?
  end
end
