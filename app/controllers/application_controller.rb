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
end
