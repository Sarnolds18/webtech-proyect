# Preview all emails at http://localhost:3000/rails/mailers/passwords_mailer
class PasswordsMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/passwords_mailer/reset
  def reset
    PasswordsMailer.reset(User.find_by(email_address: "sofia.araya@roomies.test"))
  end
end
