class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  # For the catalogs (neighborhoods and amenities).
  def require_moderator
    redirect_back_or_to root_path, alert: "Only moderators can do that." unless current_user&.moderator?
  end
end
