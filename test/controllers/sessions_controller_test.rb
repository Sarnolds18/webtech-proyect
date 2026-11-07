require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:seeker) }

  test "visitors see a Bootstrap login form and no acting user selector" do
    get new_session_path

    assert_response :success
    assert_select "form[action='#{session_path}']" do
      assert_select "input[type=email][autocomplete=username]"
      assert_select "input[type=password][autocomplete=current-password]"
      assert_select "input[type=submit].btn-primary"
    end
    assert_select "select[name=user_id]", count: 0
  end

  test "valid credentials create a session and greet the member" do
    user_agent = "Mozilla/5.0 Chrome/131.0.0.0 Safari/537.36"

    assert_difference -> { @user.sessions.count }, 1 do
      post session_path, params: { email_address: @user.email_address, password: "password123" },
                        headers: { "User-Agent" => user_agent }
    end

    assert_redirected_to root_path
    assert cookies[:session_id]
    assert_equal "Welcome back, #{@user.name}!", flash[:notice]
    assert_equal user_agent, @user.sessions.last.user_agent

    follow_redirect!
    assert_select "button", /#{Regexp.escape(@user.name)}/
    assert_select "form[action='#{session_path}'] input[value=delete]"
    assert_select "a[href='#{new_session_path}']", count: 0
  end

  test "invalid credentials do not create a session" do
    assert_no_difference -> { Session.count } do
      post session_path, params: { email_address: @user.email_address, password: "wrong" }
    end

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
    assert_equal "Try another email address or password.", flash[:alert]
  end

  test "suspended members cannot sign in" do
    @user.suspended!

    assert_no_difference -> { Session.count } do
      post session_path, params: { email_address: @user.email_address, password: "password123" }
    end

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
    assert_equal "Your account is suspended. Contact a moderator.", flash[:alert]
  end

  test "suspending a member prevents their existing cookie from accessing protected pages" do
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    @user.suspended!

    get new_property_path

    assert_redirected_to new_session_path
  end

  test "signing out deletes the session and returns to the public home" do
    act_as @user

    assert_difference -> { @user.sessions.count }, -1 do
      delete session_path
    end

    assert_response :see_other
    assert_redirected_to root_path
    assert_empty cookies[:session_id]
    assert_equal "You signed out.", flash[:notice]

    get new_property_path
    assert_redirected_to new_session_path
  end

  test "signing out without a session returns to the public home" do
    delete session_path

    assert_redirected_to root_path
  end

  test "signing in returns to the protected page requested before login" do
    get new_property_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: @user.email_address, password: "password123" }
    assert_redirected_to new_property_path

    follow_redirect!
    assert_response :success
  end

  test "a HEAD request preserves the same return URL as GET" do
    head new_property_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: @user.email_address, password: "password123" }
    assert_redirected_to new_property_path
  end

  test "a visitor's POST is not used as a return URL after login" do
    post properties_path, params: { property: { title: "A room" } }
    assert_redirected_to new_session_path

    post session_path, params: { email_address: @user.email_address, password: "password123" }
    assert_redirected_to root_path
  end

  test "visitors keep access to public pages" do
    [ root_path, listings_path, listing_path(listings(:cheap)), properties_path,
      property_path(properties(:house)), neighborhoods_path ].each do |path|
      get path
      assert_response :success
    end
  end

  test "the old acting user endpoint cannot select an account" do
    patch "/acting_user", params: { user_id: @user.id }

    assert_response :not_found
    assert_nil cookies[:session_id]
  end
end
