class SessionsController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    user = User.authenticate_by(params.permit(:email_address, :password))

    if user&.suspended?
      redirect_to new_session_path, alert: "Your account is suspended. Contact a moderator."
    elsif user
      start_new_session_for user
      redirect_to after_authentication_url, notice: "Welcome back, #{user.name}!"
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: "You signed out.", status: :see_other
  end
end
