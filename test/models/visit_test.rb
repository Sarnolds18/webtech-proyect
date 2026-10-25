require "test_helper"

class VisitTest < ActiveSupport::TestCase
  setup do
    @application = applications(:shortlisted)
    @visit = visits(:proposed)
  end

  test "new visits start as proposed" do
    assert Visit.new.proposed?
  end

  test "can be proposed in the future for a shortlisted application" do
    assert Visit.new(application: @application, scheduled_at: 2.days.from_now).valid?
  end

  test "must be scheduled in the future" do
    visit = Visit.new(application: @application, scheduled_at: 1.hour.ago)

    assert_not visit.valid?
    assert_includes visit.errors[:scheduled_at], "must be in the future"
  end

  test "must be scheduled after the application was created" do
    @application.update_columns(created_at: 5.days.from_now)
    visit = Visit.new(application: @application, scheduled_at: 2.days.from_now)

    assert_not visit.valid?
    assert_includes visit.errors[:scheduled_at], "must be after the application was created"
  end

  test "the application must be shortlisted" do
    visit = Visit.new(application: applications(:pending), scheduled_at: 2.days.from_now)

    assert_not visit.valid?
    assert_includes visit.errors[:application], "must be shortlisted before a visit is proposed"
  end

  test "past visits stay valid when their status changes later" do
    visit = visits(:completed)
    @application.update!(status: :accepted)

    assert visit.valid?
    visit.update_columns(status: "confirmed")
    assert_nothing_raised { visit.complete! }
  end

  test "an application can have several visits" do
    @application.visits.create!(scheduled_at: 5.days.from_now)

    assert_equal 3, @application.visits.count
  end

  test "upcoming and past scopes" do
    assert_equal [ visits(:proposed) ], Visit.upcoming.to_a
    assert_equal [ visits(:completed) ], Visit.past.to_a
  end

  test "a proposed visit is confirmed" do
    @visit.confirm!

    assert @visit.reload.confirmed?
  end

  test "only a proposed visit can be confirmed" do
    @visit.update!(status: :cancelled)

    error = assert_raises(ActiveRecord::RecordInvalid) { @visit.confirm! }
    assert_includes error.record.errors[:status], "can only be confirmed while it is proposed"
    assert @visit.reload.cancelled?
  end

  test "proposed and confirmed visits can be cancelled" do
    @visit.cancel!
    assert @visit.reload.cancelled?

    confirmed = @application.visits.create!(scheduled_at: 4.days.from_now, status: :confirmed)
    confirmed.cancel!
    assert confirmed.reload.cancelled?
  end

  test "completed and cancelled visits cannot be cancelled" do
    assert_raises(ActiveRecord::RecordInvalid) { visits(:completed).cancel! }

    @visit.update!(status: :cancelled)
    error = assert_raises(ActiveRecord::RecordInvalid) { @visit.cancel! }
    assert_includes error.record.errors[:status], "cannot be cancelled once it is cancelled"
  end

  test "a confirmed visit is completed" do
    @visit.update!(status: :confirmed)
    @visit.complete!

    assert @visit.reload.completed?
  end

  test "only a confirmed visit can be completed" do
    error = assert_raises(ActiveRecord::RecordInvalid) { @visit.complete! }

    assert_includes error.record.errors[:status], "can only be completed once it is confirmed"
    assert @visit.reload.proposed?
  end

  test "rescheduling cancels the visit and proposes a new one, keeping the history" do
    new_time = 6.days.from_now.change(usec: 0)

    new_visit = assert_difference -> { @application.visits.count } do
      @visit.reschedule!(new_time)
    end

    assert @visit.reload.cancelled?
    assert new_visit.proposed?
    assert_equal new_time, new_visit.scheduled_at
    assert_equal @application, new_visit.application
  end

  test "rescheduling to a past date changes nothing" do
    assert_no_difference -> { Visit.count } do
      error = assert_raises(ActiveRecord::RecordInvalid) { @visit.reschedule!(1.day.ago) }
      assert_includes error.record.errors[:scheduled_at], "must be in the future"
    end

    assert @visit.reload.proposed?
  end

  test "a completed visit cannot be rescheduled" do
    assert_no_difference -> { Visit.count } do
      assert_raises(ActiveRecord::RecordInvalid) { visits(:completed).reschedule!(3.days.from_now) }
    end
  end
end
