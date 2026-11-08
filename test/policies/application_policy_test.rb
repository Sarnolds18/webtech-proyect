require "test_helper"

class ApplicationPolicyTest < ActiveSupport::TestCase
  test "the scope returns only what the user sent or received" do
    assert_empty ApplicationPolicy::Scope.new(nil, Application).resolve
    assert_empty ApplicationPolicy::Scope.new(users(:other_seeker), Application).resolve
    assert_equal Application.all.sort, ApplicationPolicy::Scope.new(users(:seeker), Application).resolve.sort
    assert_equal Application.all.sort, ApplicationPolicy::Scope.new(users(:host), Application).resolve.sort
    assert_equal Application.count, ApplicationPolicy::Scope.new(users(:moderator), Application).resolve.count
  end

  test "the scope of a host does not include the applications of other hosts" do
    other_host = User.create!(name: "Tomás Fuentes", email_address: "tomas.fuentes@roomies.test", password: "password123")
    assert_empty ApplicationPolicy::Scope.new(other_host, Application).resolve
  end

  test "an application is read by its seeker, the host and the moderators" do
    application = applications(:pending)

    assert ApplicationPolicy.new(users(:seeker), application).show?
    assert ApplicationPolicy.new(users(:host), application).show?
    assert ApplicationPolicy.new(users(:moderator), application).show?
    assert_not ApplicationPolicy.new(users(:other_seeker), application).show?
    assert_not ApplicationPolicy.new(nil, application).show?
  end

  test "only the host answers, and a moderator cannot accept for them" do
    application = applications(:pending)

    %i[shortlist? reject? accept?].each do |action|
      assert ApplicationPolicy.new(users(:host), application).public_send(action), action
      assert_not ApplicationPolicy.new(users(:moderator), application).public_send(action), action
      assert_not ApplicationPolicy.new(users(:seeker), application).public_send(action), action
    end
  end

  test "only the seeker withdraws" do
    assert ApplicationPolicy.new(users(:seeker), applications(:pending)).withdraw?
    assert_not ApplicationPolicy.new(users(:host), applications(:pending)).withdraw?
  end

  test "members apply to listings that are not theirs" do
    assert ApplicationPolicy.new(users(:other_seeker), listings(:cheap).applications.new).create?
    assert ApplicationPolicy.new(users(:moderator), listings(:cheap).applications.new).create?
    assert_not ApplicationPolicy.new(users(:host), listings(:cheap).applications.new).create?
    assert_not ApplicationPolicy.new(nil, listings(:cheap).applications.new).create?
  end
end
