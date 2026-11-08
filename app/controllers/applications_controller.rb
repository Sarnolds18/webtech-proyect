# Applications are private: only the seeker who wrote one, the host of the listing and the moderators
# read it (ApplicationPolicy). Lists come from the policy scope, so the query itself returns only what
# the user may see, and every single application is authorized, so guessing an id leads nowhere.
class ApplicationsController < ApplicationController
  before_action :require_user
  before_action :set_application, only: %i[show withdraw shortlist reject accept]
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  # "Applications I sent" and "Applications I received", both cut from the same policy scope. For a
  # member nothing else is left in it; a moderator also gets every other application.
  def index
    applications = policy_scope(Application).includes(:seeker, listing: { property: %i[neighborhood host] }).recent_first
    my_listings = Listing.joins(:property).where(properties: { host_id: current_user.id }).select(:id)

    @sent = applications.where(seeker: current_user)
    @received = applications.where(listing_id: my_listings).group_by(&:listing)
    @others = applications.where.not(seeker: current_user).where.not(listing_id: my_listings)
  end

  def show
    authorize @application
    @visits = @application.visits.chronological
    @visit = Visit.new
  end

  # Applying happens inside the "application_block" Turbo Frame of the listing page, so both outcomes
  # answer with that block only: the confirmation, or the form with the errors next to each field.
  def create
    @listing = Listing.find(params[:listing_id])
    application = authorize @listing.applications.build(application_params.merge(seeker: current_user))

    if application.save
      render_application_block application, notice: "Your application was sent. The host will answer you soon."
    else
      render_application_block application, status: :unprocessable_entity
    end
  end

  def withdraw
    authorize @application
    @application.withdraw!
    render_application_block @application, notice: "You withdrew your application."
  rescue ActiveRecord::RecordInvalid
    render_application_block @application, alert: @application.errors.full_messages.to_sentence,
                                           status: :unprocessable_entity
  end

  # The inbox actions answer with Turbo Streams that update the row, the pending counter, the listing's
  # status (accepting reserves it) and the flash.
  def shortlist
    authorize @application
    answer(:shortlist!, "#{@application.seeker.name} is on the shortlist. You can now propose a visit.")
  end

  def reject
    authorize @application
    answer(:reject!, "The application from #{@application.seeker.name} was rejected.")
  end

  # Accepting also rejects every other undecided application, so every row of the listing is replaced.
  def accept
    authorize @application
    answer(:accept!, "You accepted #{@application.seeker.name}. The listing is now reserved.", every_row: true)
  end

  private

  def set_application
    @application = Application.includes(:seeker, listing: { property: :neighborhood }).find(params[:id])
    @listing = @application.listing
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
        rows = every_row ? policy_scope(Application).where(listing: @listing).includes(:seeker) : [ @application ]
        render turbo_stream: [
          *rows.map { |row| turbo_stream.replace(row, partial: "applications/inbox_row", locals: { application: row }) },
          turbo_stream.update("pending_count", @listing.applications.awaiting_answer.count.to_s),
          turbo_stream.update("listing_status", helpers.status_badge(@listing.status)),
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
