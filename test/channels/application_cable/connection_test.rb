require "test_helper"
require "action_cable/connection/test_case"

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    tests ApplicationCable::Connection

    test "active members connect with their signed session cookie" do
      user = users(:seeker)
      cookies.signed[:session_id] = user.sessions.create!.id

      connect

      assert_equal user, connection.current_user
    end

    test "visitors cannot connect" do
      assert_reject_connection { connect }
    end

    test "a deleted session cannot connect" do
      session = users(:seeker).sessions.create!
      cookies.signed[:session_id] = session.id
      session.destroy!

      assert_reject_connection { connect }
    end

    test "suspended members cannot connect with an existing session" do
      user = users(:seeker)
      cookies.signed[:session_id] = user.sessions.create!.id
      user.suspended!

      assert_reject_connection { connect }
    end
  end
end
