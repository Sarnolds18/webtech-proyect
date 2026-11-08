# Members report a listing that is not theirs from its page; moderators read the reports and resolve
# them: dismiss (nothing wrong) or take action (the listing is withdrawn). Every decision is logged as
# a ModerationAction.
class ReportsController < ApplicationController
  before_action :require_user
  before_action :set_report, only: %i[show dismiss take_action]
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def index
    authorize Report
    reports = policy_scope(Report).includes(:reporter, listing: { property: :neighborhood }).recent_first
    @open_reports = reports.unresolved
    @resolved_reports = reports.resolved.limit(20)
  end

  def show
    authorize @report
    @actions = @report.moderation_actions.includes(:moderator).recent_first
  end

  def create
    @listing = Listing.find(params[:listing_id])
    report = authorize @listing.reports.build(report_params.merge(reporter: current_user))

    if report.save
      redirect_to @listing, notice: "Thanks for the report. A moderator will review this listing."
    else
      redirect_to @listing, alert: "The report was not sent: #{report.errors.full_messages.to_sentence}."
    end
  end

  def dismiss
    authorize @report
    resolve("The report was dismissed. The listing stays as it is.") { @report.dismiss!(moderator: current_user, notes:) }
  end

  def take_action
    authorize @report
    resolve("The listing was withdrawn and its open reports were closed.") do
      @report.take_action!(moderator: current_user, notes:)
    end
  end

  private

  def set_report
    @report = Report.includes(:reporter, listing: { property: %i[neighborhood host] }).find(params[:id])
  end

  def report_params
    params.expect(report: %i[reason details])
  end

  def notes
    params.dig(:moderation, :notes)
  end

  def resolve(notice)
    yield
    redirect_to reports_path, notice: notice
  rescue ActiveRecord::RecordInvalid => error
    redirect_to @report, alert: error.record.errors.full_messages.to_sentence
  end
end
