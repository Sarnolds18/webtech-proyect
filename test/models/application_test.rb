require "test_helper"

class ApplicationTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  def build_application(**attributes)
    Application.new(
      listing: listings(:pricey), seeker: users(:other_seeker),
      message: "I'd love to visit the room.", move_in_date: 1.month.from_now.to_date, stay_months: 12,
      **attributes
    )
  end

  test "valid application" do
    assert build_application.valid?
  end

  test "new applications start as pending" do
    assert build_application.pending?
  end

  test "requires a message and a move-in date" do
    application = build_application(message: "", move_in_date: nil)

    assert_not application.valid?
    assert application.errors.added?(:message, :blank)
    assert application.errors.added?(:move_in_date, :blank)
  end

  test "stay must be at least one month" do
    assert_not build_application(stay_months: 0).valid?
  end

  test "a seeker cannot apply twice to the same listing" do
    application = build_application(seeker: users(:seeker))

    assert_not application.valid?
    assert_includes application.errors[:seeker_id], "has already applied to this listing"
  end

  test "the host cannot apply to their own listing" do
    application = build_application(seeker: users(:host))

    assert_not application.valid?
    assert_includes application.errors[:seeker], "cannot apply to their own listing"
  end

  test "only published listings accept new applications" do
    application = build_application(listing: listings(:draft))

    assert_not application.valid?
    assert_includes application.errors[:listing], "is not accepting applications"

    %i[reserved rented withdrawn].each do |status|
      listings(:pricey).update!(status: status)
      assert_not build_application.valid?, "#{status} listing should not accept applications"
    end
  end

  test "existing applications stay valid after the listing stops being published" do
    listings(:pricey).reserved!

    assert applications(:shortlisted).reload.valid?
  end

  test "pending and shortlisted applications can be withdrawn" do
    %i[pending shortlisted].each do |name|
      applications(name).withdraw!

      assert applications(name).reload.withdrawn?
    end
  end

  test "decided applications cannot be withdrawn" do
    application = applications(:shortlisted)

    %i[accepted rejected withdrawn].each do |status|
      application.update!(status: status)

      error = assert_raises(ActiveRecord::RecordInvalid) { application.withdraw! }
      assert_includes error.record.errors[:status], "cannot be withdrawn once it is #{status}"
      assert_equal status.to_s, application.reload.status
    end
  end

  test "only pending applications on a published listing can be shortlisted" do
    applications(:pending).shortlist!
    assert applications(:pending).reload.shortlisted?

    error = assert_raises(ActiveRecord::RecordInvalid) { applications(:shortlisted).shortlist! }
    assert_includes error.record.errors[:status], "cannot be shortlisted once it is shortlisted"
  end

  test "pending and shortlisted applications can be rejected" do
    %i[pending shortlisted].each do |name|
      applications(name).reject!

      assert applications(name).reload.rejected?
    end

    assert_raises(ActiveRecord::RecordInvalid) { applications(:pending).reject! }
  end

  test "accepting rejects the other undecided applications and reserves the listing" do
    listing = listings(:pricey)
    rival = build_application(listing: listing)
    rival.save!
    already_withdrawn = Application.create!(
      listing: listing, seeker: users(:moderator), status: :withdrawn,
      message: "Changed my mind.", move_in_date: 2.months.from_now.to_date, stay_months: 12
    )

    applications(:shortlisted).accept!

    assert applications(:shortlisted).reload.accepted?
    assert rival.reload.rejected?
    assert already_withdrawn.reload.withdrawn?, "decided applications are left alone"
    assert listing.reload.reserved?
    assert applications(:pending).reload.pending?, "applications of other listings are left alone"
  end

  test "a listing that is not published cannot accept" do
    listings(:pricey).reserved!

    error = assert_raises(ActiveRecord::RecordInvalid) { applications(:shortlisted).accept! }
    assert_includes error.record.errors[:listing], "is not accepting applications"
    assert applications(:shortlisted).reload.shortlisted?
  end

  test "decided applications cannot be accepted" do
    application = applications(:shortlisted)
    application.rejected!

    assert_raises(ActiveRecord::RecordInvalid) { application.accept! }
    assert listings(:pricey).reload.published?
  end

  test "accepting rolls everything back when a step fails" do
    listing = listings(:pricey)
    rival = build_application(listing: listing)
    rival.save!
    application = applications(:shortlisted)

    # Make the last step of the transaction fail, after the application was accepted and the rival rejected.
    application.listing.define_singleton_method(:reserved!) { raise ActiveRecord::RecordInvalid, self }

    assert_raises(ActiveRecord::RecordInvalid) { application.accept! }

    assert application.reload.shortlisted?
    assert rival.reload.pending?
    assert listing.reload.published?
  end

  test "database allows only one accepted application per listing" do
    applications(:shortlisted).update!(status: :accepted)

    assert_raises(ActiveRecord::RecordNotUnique) do
      build_application(status: :accepted).save!
    end
  end

  test "status scopes" do
    assert_equal [ applications(:pending) ], Application.awaiting_answer.to_a
    assert_equal 2, Application.undecided.count
  end

  test "creating an application enqueues one notification for the host" do
    application = build_application

    assert_enqueued_emails 1 do
      application.save!
    end
    assert_enqueued_email_with ApplicationNotificationMailer, :received, params: { application: application }
  end

  test "an invalid application does not enqueue a notification" do
    assert_enqueued_emails 0 do
      assert_not build_application(message: "").save
    end
  end

  test "shortlisting and rejecting notify the seeker with the answer that triggered the email" do
    application = applications(:pending)

    assert_enqueued_emails 1 do
      application.shortlist!
    end
    assert_enqueued_email_with ApplicationNotificationMailer, :answered,
      params: { application: application, status: "shortlisted" }

    assert_enqueued_emails 1 do
      application.reject!
    end
    assert_enqueued_email_with ApplicationNotificationMailer, :answered,
      params: { application: application, status: "rejected" }
  end

  test "editing a message or withdrawing an application does not send an answer notification" do
    application = applications(:pending)

    assert_enqueued_emails 0 do
      application.update!(message: "Here is some more information.")
      application.withdraw!
    end
  end

  test "accepting notifies the accepted seeker and every automatically rejected seeker" do
    application = applications(:shortlisted)
    pending_rival = build_application
    pending_rival.save!
    shortlisted_rival = build_application(seeker: users(:moderator), status: :shortlisted)
    shortlisted_rival.save!

    assert_enqueued_emails 3 do
      application.accept!
    end

    assert_enqueued_email_with ApplicationNotificationMailer, :answered,
      params: { application: application, status: "accepted" }
    [ pending_rival, shortlisted_rival ].each do |rival|
      assert rival.reload.rejected?
      assert_enqueued_email_with ApplicationNotificationMailer, :answered,
        params: { application: rival, status: "rejected" }
    end
  end

  test "a failed acceptance enqueues no emails and rolls back the automatic rejections" do
    application = applications(:shortlisted)
    rival = build_application
    rival.save!
    application.listing.define_singleton_method(:reserved!) { raise ActiveRecord::RecordInvalid, self }

    assert_enqueued_emails 0 do
      assert_raises(ActiveRecord::RecordInvalid) { application.accept! }
    end

    assert application.reload.shortlisted?
    assert rival.reload.pending?
    assert application.listing.reload.published?
  end

  test "rolling back an outer transaction does not enqueue answer notifications" do
    application = applications(:shortlisted)
    rival = build_application
    rival.save!

    assert_enqueued_emails 0 do
      Application.transaction(requires_new: true) do
        application.accept!
        raise ActiveRecord::Rollback
      end
    end

    assert application.reload.shortlisted?
    assert rival.reload.pending?
  end
end
