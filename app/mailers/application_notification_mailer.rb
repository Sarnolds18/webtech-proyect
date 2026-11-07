class ApplicationNotificationMailer < ApplicationMailer
  def received
    @application = params[:application]
    @listing = @application.listing
    mail to: @listing.host.email_address, subject: "New application for #{@listing.title}"
  end

  def answered
    @application = params[:application]
    @listing = @application.listing
    # Keep the answer that triggered this job, even if the application changes again before delivery.
    @status = params[:status] || @application.status
    mail to: @application.seeker.email_address, subject: "Your application for #{@listing.title} was #{@status}"
  end
end
