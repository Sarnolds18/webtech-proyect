require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes the email address" do
    user = User.new(email_address: "  Someone@Roomies.TEST ")

    assert_equal "someone@roomies.test", user.email_address
  end

  test "email address is unique regardless of case" do
    user = User.new(name: "Copy", email_address: "SOFIA.ARAYA@roomies.test", password: "password123")

    assert_not user.valid?
    assert user.errors.added?(:email_address, :taken, value: "sofia.araya@roomies.test")
  end

  test "new users are active members" do
    user = User.new

    assert user.member?
    assert user.active?
  end

  test "a host's properties and a seeker's applications" do
    assert_equal 2, users(:host).properties.count
    assert_equal 2, users(:seeker).applications.count
  end
end
