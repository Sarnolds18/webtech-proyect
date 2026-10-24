# Picks the user the visitor is acting as, chosen from the navbar. There is no login until
# Assignment 4, so this is how every action gets an author. A blank choice means "visitor".
class ActingUsersController < ApplicationController
  def update
    user = User.find_by(id: params[:user_id])
    session[:acting_user_id] = user&.id

    redirect_back_or_to root_path, notice: user ? "You are now acting as #{user.name}." : "You are now browsing as a visitor."
  end
end
