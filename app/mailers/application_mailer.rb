class ApplicationMailer < ActionMailer::Base
  # The sender comes from config.action_mailer.default_options (a real Brevo address in production).
  layout "mailer"
end
