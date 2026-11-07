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

  test "passwords need at least eight characters" do
    user = User.new(name: "Antonia Díaz", email_address: "antonia.diaz@roomies.test", password: "short")

    assert_not user.valid?
    assert user.errors.added?(:password, :too_short, count: 8)

    user.password = "12345678"
    assert user.valid?
  end

  test "existing users can update their details without changing their password" do
    user = users(:seeker).reload

    assert user.update(name: "Sofía Araya Pérez")
    assert user.authenticate("password123")
  end

  test "a host's properties and a seeker's applications" do
    assert_equal 2, users(:host).properties.count
    assert_equal 2, users(:seeker).applications.count
  end
end
