require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset email includes the member's name, reset link and expiration in both formats" do
    user = users(:seeker)
    email = PasswordsMailer.reset(user)

    assert_equal [ user.email_address ], email.to
    assert_equal [ "no-reply@roomies.test" ], email.from
    assert_equal "Reset your password", email.subject

    [ email.html_part, email.text_part ].each do |part|
      body = part.body.decoded
      assert_includes body, user.name
      assert_includes body, "15 minutes"
      assert_includes body, "If you did not request this change"

      link = if part.mime_type == "text/html"
        Nokogiri::HTML.fragment(body).at_css("a")["href"]
      else
        body.lines.find { |line| line.start_with?("http") }.strip
      end
      uri = URI.parse(link)
      assert_includes %w[http https], uri.scheme
      route = Rails.application.routes.recognize_path(uri.path)
      assert_equal "passwords", route[:controller]
      assert_equal "edit", route[:action]
      assert_equal user, User.find_by_password_reset_token!(route[:token])
    end
  end

  test "password reset email is delivered through Active Job" do
    assert_emails 1 do
      perform_enqueued_jobs do
        PasswordsMailer.reset(users(:seeker)).deliver_later
      end
    end

    assert_equal [ users(:seeker).email_address ], ActionMailer::Base.deliveries.last.to
  end
end
