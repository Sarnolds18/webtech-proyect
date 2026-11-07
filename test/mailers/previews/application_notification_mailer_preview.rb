class ApplicationNotificationMailerPreview < ActionMailer::Preview
  def received
    ApplicationNotificationMailer.with(application: sample_application).received
  end

  def shortlisted
    ApplicationNotificationMailer.with(application: sample_application, status: "shortlisted").answered
  end

  def accepted
    ApplicationNotificationMailer.with(application: sample_application, status: "accepted").answered
  end

  def rejected
    ApplicationNotificationMailer.with(application: sample_application, status: "rejected").answered
  end

  private

  def sample_application
    Application.joins(:seeker).find_by!(users: { email_address: "sofia.araya@roomies.test" })
  end
end
