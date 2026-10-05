require "test_helper"

class VisitTest < ActiveSupport::TestCase
  setup do
    @application = applications(:pending)
  end

  test "new visits start as proposed" do
    assert Visit.new.proposed?
  end

  test "must be scheduled after the application was created" do
    visit = Visit.new(application: @application, scheduled_at: @application.created_at - 1.day)

    assert_not visit.valid?
    assert_includes visit.errors[:scheduled_at], "must be after the application was created"
  end

  test "can be scheduled after the application was created" do
    assert Visit.new(application: @application, scheduled_at: 2.days.from_now).valid?
  end

  test "an application can have several visits" do
    @application.visits.create!(scheduled_at: 5.days.from_now)

    assert_equal 2, @application.visits.count
  end

  test "upcoming and past scopes" do
    assert_equal [ visits(:proposed) ], Visit.upcoming.to_a
    assert_equal [ visits(:completed) ], Visit.past.to_a
  end
end
