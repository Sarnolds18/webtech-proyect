require "test_helper"

class ApplicationNotificationMailerTest < ActionMailer::TestCase
  test "new applications notify only the host with the applicant's message and inbox link" do
    application = applications(:pending)
    email = ApplicationNotificationMailer.with(application: application).received

    assert_equal [ application.listing.host.email_address ], email.to
    assert_equal [ "no-reply@roomies.test" ], email.from
    assert_equal "New application for #{application.listing.title}", email.subject
    assert_nil email.cc
    assert_nil email.bcc

    [ email.html_part, email.text_part ].each do |part|
      body = part.body.decoded
      assert_includes body, application.seeker.name
      assert_includes body, application.message
      route = route_from(part)
      assert_equal "inboxes", route[:controller]
      assert_equal application.listing_id.to_s, route[:listing_id]
    end
  end

  test "each answer notifies only the seeker and links to their application" do
    application = applications(:pending)

    %w[shortlisted accepted rejected].each do |status|
      email = ApplicationNotificationMailer.with(application: application, status: status).answered

      assert_equal [ application.seeker.email_address ], email.to
      assert_equal "Your application for #{application.listing.title} was #{status}", email.subject
      assert_nil email.cc
      assert_nil email.bcc

      [ email.html_part, email.text_part ].each do |part|
        body = part.body.decoded
        assert_includes body, application.seeker.name
        assert_includes body, "was #{status}"
        route = route_from(part)
        assert_equal "applications", route[:controller]
        assert_equal application.id.to_s, route[:id]
      end
    end
  end

  test "the answer keeps its original status if the application changes before delivery" do
    application = applications(:pending)
    email = ApplicationNotificationMailer.with(application: application, status: "shortlisted").answered
    application.update_columns(status: "accepted")

    assert_includes email.subject, "was shortlisted"
    assert_includes email.text_part.body.decoded, "was shortlisted"
  end

  test "new application notifications are delivered through Active Job" do
    application = applications(:pending)

    assert_emails 1 do
      perform_enqueued_jobs do
        ApplicationNotificationMailer.with(application: application).received.deliver_later
      end
    end

    assert_equal [ application.listing.host.email_address ], ActionMailer::Base.deliveries.last.to
  end

  private

  def route_from(part)
    body = part.body.decoded
    link = if part.mime_type == "text/html"
      Nokogiri::HTML.fragment(body).at_css("a")["href"]
    else
      body.lines.find { |line| line.start_with?("http") }.strip
    end
    uri = URI.parse(link)
    assert_includes %w[http https], uri.scheme
    Rails.application.routes.recognize_path(uri.path)
  end
end
