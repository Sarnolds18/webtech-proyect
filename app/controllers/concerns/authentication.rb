module Authentication
  extend ActiveSupport::Concern

  # Public pages stay available to visitors; protected actions opt in with `require_user`.
  included do
    before_action :resume_session
    helper_method :authenticated?, :current_user
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_user, raise: false, **options
    end
  end

  private
    def authenticated?
      current_user.present?
    end

    def current_user
      Current.user
    end

    def require_user
      return if current_user

      session[:return_to_after_authenticating] = request.url if request.get? || request.head?
      redirect_to new_session_path, alert: "Sign in or create an account to continue."
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    # Suspended accounts cannot resume a session, even with an existing cookie.
    def find_session_by_cookie
      return unless cookies.signed[:session_id]

      Session.joins(:user).where(users: { status: "active" }).find_by(id: cookies.signed[:session_id])
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session&.destroy
      Current.session = nil
      cookies.delete(:session_id)
    end
end
