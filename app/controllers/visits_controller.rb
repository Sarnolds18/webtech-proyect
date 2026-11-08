# The host proposes, reschedules and completes visits; the seeker confirms them; either of them cancels.
# Everything happens on the application page. VisitPolicy decides who does what.
class VisitsController < ApplicationController
  before_action :require_user
  before_action :set_application, only: :create
  before_action :set_visit, except: :create
  after_action :verify_authorized

  def create
    @visit = authorize @application.visits.build(visit_params)

    if @visit.save
      redirect_to @application, notice: "The visit was proposed. #{@application.seeker.name} can now confirm it."
    else
      @visits = @application.visits.chronological
      render "applications/show", status: :unprocessable_entity
    end
  end

  def confirm
    authorize @visit
    transition("The visit is confirmed.") { @visit.confirm! }
  end

  def cancel
    authorize @visit
    transition("The visit was cancelled.") { @visit.cancel! }
  end

  def complete
    authorize @visit
    transition("The visit is marked as completed. The applicant can now review the property.") { @visit.complete! }
  end

  # The old visit is cancelled and a new proposed one takes its place, so the seeker confirms it again.
  def reschedule
    authorize @visit
    new_time = params.expect(visit: [ :scheduled_at ])[:scheduled_at]
    transition("The visit was rescheduled. #{@application.seeker.name} needs to confirm the new date.") do
      @visit.reschedule!(new_time)
    end
  end

  private

  def set_application
    @application = Application.includes(:seeker, listing: { property: :neighborhood }).find(params[:application_id])
  end

  def set_visit
    @visit = Visit.includes(application: [ :seeker, { listing: :property } ]).find(params[:id])
    @application = @visit.application
  end

  def transition(notice)
    yield
    redirect_to @application, notice: notice
  rescue ActiveRecord::RecordInvalid
    redirect_to @application, alert: @visit.errors.full_messages.to_sentence
  end

  def visit_params
    params.expect(visit: [ :scheduled_at ])
  end
end
