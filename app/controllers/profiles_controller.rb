class ProfilesController < ApplicationController
  before_action :require_user
  before_action :set_user

  def show
    @properties = @user.properties.includes(:neighborhood).order(:title)
    @applications = @user.applications.includes(listing: :property).recent_first
  end

  def edit
  end

  def update
    if @user.update(profile_params)
      redirect_to profile_path, notice: "Your profile was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # The profile always belongs to the signed-in member, never to an id from the request.
  def set_user
    @user = current_user
  end

  def profile_params
    attributes = params.expect(user: %i[name email_address phone bio password password_confirmation password_challenge])

    if attributes[:password].present?
      # has_secure_password checks the old password when the challenge is not nil.
      # Missing challenges must also be checked, rather than skipping that validation.
      attributes[:password_challenge] = attributes[:password_challenge].to_s
    else
      attributes = attributes.except(:password, :password_confirmation, :password_challenge)
    end

    attributes
  end
end
