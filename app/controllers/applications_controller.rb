# Applications are private by domain rule; these pages are public ONLY until authentication
# and Pundit policies arrive in Assignment 4.
class ApplicationsController < ApplicationController
  before_action :set_application, only: :show

  def index
    @applications = Application.includes(:seeker, listing: { property: :neighborhood }).recent_first
  end

  def show
    @visits = @application.visits.chronological
  end

  private

  def set_application
    @application = Application.includes(:seeker, listing: { property: :neighborhood }).find(params[:id])
  end
end
