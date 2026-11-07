class RegistrationsController < ApplicationController
  before_action :redirect_signed_in_user

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      start_new_session_for @user
      redirect_to after_authentication_url, notice: "Welcome to Roomies, #{@user.name}!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def redirect_signed_in_user
    redirect_to root_path, notice: "You already have an account." if current_user
  end

  # Role and status use the model defaults: a registration always creates an active member.
  def registration_params
    params.expect(user: %i[name email_address password password_confirmation])
  end
end
