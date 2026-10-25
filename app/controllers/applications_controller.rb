# Applications are private by domain rule; these pages are public ONLY until authentication
# and Pundit policies arrive in Assignment 4.
class ApplicationsController < ApplicationController
  before_action :require_user, only: %i[create withdraw shortlist reject accept]
  before_action :set_application, only: %i[show withdraw shortlist reject accept]
  before_action :require_seeker, only: :withdraw
  before_action :require_host, only: %i[shortlist reject accept]

  def index
    @applications = Application.includes(:seeker, listing: { property: :neighborhood }).recent_first
  end

  def show
    @visits = @application.visits.chronological
    @visit = Visit.new
  end

  # Applying happens inside the "application_block" Turbo Frame of the listing page, so both outcomes
  # answer with that block only: the confirmation, or the form with the errors next to each field.
  def create
    @listing = Listing.find(params[:listing_id])
    application = @listing.applications.build(application_params.merge(seeker: current_user))

    if application.save
      render_application_block application, notice: "Your application was sent. The host will answer you soon."
    else
      render_application_block application, status: :unprocessable_entity
    end
  end

  def withdraw
    @application.withdraw!
    render_application_block @application, notice: "You withdrew your application."
  rescue ActiveRecord::RecordInvalid
    render_application_block @application, alert: @application.errors.full_messages.to_sentence,
                                           status: :unprocessable_entity
  end

  # The inbox actions answer with Turbo Streams that update the row, the pending counter and the flash.
  def shortlist
    answer(:shortlist!, "#{@application.seeker.name} is on the shortlist. You can now propose a visit.")
  end

  def reject
    answer(:reject!, "The application from #{@application.seeker.name} was rejected.")
  end

  # Accepting also rejects every other undecided application, so every row of the listing is replaced.
  def accept
    answer(:accept!, "You accepted #{@application.seeker.name}. The listing is now reserved.", every_row: true)
  end

  private

  def set_application
    @application = Application.includes(:seeker, listing: { property: :neighborhood }).find(params[:id])
    @listing = @application.listing
  end

  # Only the seeker takes back their own application.
  def require_seeker
    return if @application.seeker == current_user

    redirect_to @listing, alert: "Only the applicant can withdraw this application."
  end

  # Only the host answers the applications of their listings. Assignment 4 moves this to a Pundit policy.
  def require_host
    redirect_to @listing, alert: "Only the host of this listing can answer its applications." unless @listing.host == current_user
  end

  def render_application_block(application, status: :ok, **messages)
    render partial: "listings/application_block", status: status,
           locals: { listing: @listing, application: application, **messages }
  end

  def answer(event, notice, every_row: false)
    @application.public_send(event)

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = notice
        rows = every_row ? @listing.applications.includes(:seeker) : [ @application ]
        render turbo_stream: [
          *rows.map { |row| turbo_stream.replace(row, partial: "applications/inbox_row", locals: { application: row }) },
          turbo_stream.update("pending_count", @listing.applications.awaiting_answer.count.to_s),
          turbo_stream.replace("flash", partial: "layouts/flash")
        ]
      end
      format.html { redirect_to listing_inbox_path(@listing), notice: notice }
    end
  rescue ActiveRecord::RecordInvalid
    alert = @application.errors.full_messages.to_sentence

    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = alert
        render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash"), status: :unprocessable_entity
      end
      format.html { redirect_to listing_inbox_path(@listing), alert: alert }
    end
  end

  def application_params
    params.expect(application: %i[message move_in_date stay_months])
  end
end
