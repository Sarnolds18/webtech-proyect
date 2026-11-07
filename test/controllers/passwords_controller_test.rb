require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:seeker) }

  test "new" do
    get new_password_path
    assert_response :success
    assert_select "form[action='#{passwords_path}']" do
      assert_select "label[for=email_address]"
      assert_select "input[type=email][required]"
      assert_select "input[type=submit].btn-primary"
    end
  end

  test "create" do
    post passwords_path, params: { email_address: @user.email_address }
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "reset instructions sent"
  end

  test "create for an unknown user redirects but sends no mail" do
    post passwords_path, params: { email_address: "missing-user@example.com" }
    assert_enqueued_emails 0
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "reset instructions sent"
  end

  test "edit" do
    get edit_password_path(@user.password_reset_token)
    assert_response :success
    assert_select "label[for=password]"
    assert_select "label[for=password_confirmation]"
    assert_select "input[type=password][autocomplete=new-password][minlength='8']", count: 2
  end

  test "edit with invalid password reset token" do
    get edit_password_path("invalid token")
    assert_redirected_to new_password_path

    follow_redirect!
    assert_notice "reset link is invalid"
  end

  test "update" do
    act_as @user
    @user.sessions.create!(user_agent: "Another device")
    token = @user.password_reset_token

    assert_changes -> { @user.reload.password_digest } do
      assert_difference -> { @user.sessions.count }, -2 do
        put password_path(token), params: { password: "newpassword123", password_confirmation: "newpassword123" }
        assert_redirected_to new_session_path
      end
    end

    assert @user.authenticate("newpassword123")
    assert_not @user.authenticate("password123")
    follow_redirect!
    assert_notice "Your password was reset"

    get new_property_path
    assert_redirected_to new_session_path

    get edit_password_path(token)
    assert_redirected_to new_password_path
  end

  test "update with non matching passwords" do
    @user.sessions.create!
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      assert_no_difference -> { @user.sessions.count } do
        put password_path(token), params: { password: "newpassword123", password_confirmation: "different123" }
      end
    end

    assert_response :unprocessable_entity
    assert_select "#password_confirmation_error", /doesn't match/
    assert_select "form[action='#{password_path(token)}']"
  end

  test "short passwords render their validation error without changing the password" do
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(@user.password_reset_token), params: { password: "short", password_confirmation: "short" }
    end

    assert_response :unprocessable_entity
    assert_select "#password_error", /too short/
  end

  test "blank passwords do not report a successful reset or close sessions" do
    @user.sessions.create!

    assert_no_changes -> { @user.reload.password_digest } do
      assert_no_difference -> { @user.sessions.count } do
        put password_path(@user.password_reset_token), params: { password: "", password_confirmation: "" }
      end
    end

    assert_response :unprocessable_entity
    assert_select "#password_error", /can't be blank/
  end

  test "an expired token cannot open the reset form" do
    token = @user.password_reset_token

    travel 16.minutes do
      get edit_password_path(token)
      assert_redirected_to new_password_path
    end
  end

  test "an invalid token cannot change a password" do
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path("invalid-token"), params: { password: "newpassword123", password_confirmation: "newpassword123" }
    end

    assert_redirected_to new_password_path
  end

  private
    def assert_notice(text)
      assert_select "div", /#{text}/
    end
end
