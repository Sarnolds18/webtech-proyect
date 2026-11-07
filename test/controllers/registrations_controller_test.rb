require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  def registration_params(**overrides)
    { name: "Antonia Díaz", email_address: "antonia.diaz@roomies.test",
      password: "password123", password_confirmation: "password123" }.merge(overrides)
  end

  test "visitors see a sign up form with labeled fields" do
    get new_registration_path

    assert_response :success
    assert_select "form[action='#{registration_path}']" do
      %w[name email_address password password_confirmation].each do |field|
        assert_select "label[for=user_#{field}]"
        assert_select "input#user_#{field}[required]"
      end
      assert_select "input[type=password][minlength='8']", count: 2
      assert_select "input[name='user[role]']", count: 0
    end
  end

  test "registration creates an active member and signs them in ignoring privileged params" do
    assert_difference -> { User.count }, 1 do
      assert_difference -> { Session.count }, 1 do
        post registration_path, params: { user: registration_params(role: "moderator", status: "suspended") }
      end
    end

    user = User.find_by!(email_address: "antonia.diaz@roomies.test")
    assert user.member?
    assert user.active?
    assert user.authenticate("password123")
    assert_equal 1, user.sessions.count
    assert cookies[:session_id]
    assert_redirected_to root_path
    assert_equal "Welcome to Roomies, Antonia Díaz!", flash[:notice]

    get new_property_path
    assert_response :success
  end

  test "a duplicate email renders the errors without creating a user or a session" do
    assert_no_difference -> { User.count + Session.count } do
      post registration_path, params: { user: registration_params(email_address: " SOFIA.ARAYA@roomies.test ") }
    end

    assert_response :unprocessable_entity
    assert_select "#email_address_error", /already been taken/
    assert_nil cookies[:session_id]
  end

  test "a short password is rejected by the server" do
    assert_no_difference -> { User.count + Session.count } do
      post registration_path, params: { user: registration_params(password: "short", password_confirmation: "short") }
    end

    assert_response :unprocessable_entity
    assert_select "#password_error", /too short/
  end

  test "password confirmation must match" do
    assert_no_difference -> { User.count + Session.count } do
      post registration_path, params: { user: registration_params(password_confirmation: "different123") }
    end

    assert_response :unprocessable_entity
    assert_select "#password_confirmation_error", /doesn't match/
  end

  test "missing required details render errors and preserve the entered name" do
    assert_no_difference -> { User.count + Session.count } do
      post registration_path, params: { user: registration_params(email_address: "", password: "", password_confirmation: "") }
    end

    assert_response :unprocessable_entity
    assert_select "#email_address_error"
    assert_select "#password_error"
    assert_select "input#user_name[value='Antonia Díaz']"
  end

  test "signed in members cannot register another account" do
    act_as users(:seeker)
    get new_registration_path
    assert_redirected_to root_path

    assert_no_difference -> { User.count + Session.count } do
      post registration_path, params: { user: registration_params }
    end

    assert_redirected_to root_path
    assert_equal "You already have an account.", flash[:notice]
  end

  test "registration returns to the protected page requested before signing up" do
    get new_property_path
    assert_redirected_to new_session_path

    post registration_path, params: { user: registration_params }
    assert_redirected_to new_property_path
  end

  test "visitors can reach sign up from the navbar and login page" do
    get root_path
    assert_select "nav a[href='#{new_registration_path}']", "Sign up"

    get new_session_path
    assert_select "a[href='#{new_registration_path}']", "Create an account"
  end
end
