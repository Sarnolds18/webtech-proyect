require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "visitors must sign in to view, edit or update a profile" do
    get profile_path
    assert_redirected_to new_session_path
    get edit_profile_path
    assert_redirected_to new_session_path

    assert_no_changes -> { users(:seeker).reload.name } do
      patch profile_path, params: { user: { name: "Changed" } }
    end
    assert_redirected_to new_session_path
  end

  test "members see only their own profile and sent applications" do
    user = users(:seeker)
    user.update!(phone: "+56 9 5550 3001", bio: "I enjoy sharing a home.")
    act_as user

    get profile_path(id: users(:host).id)

    assert_response :success
    assert_select "h2", user.name
    assert_select "dd", user.email_address
    assert_select "dd", user.phone
    assert_select "a[href='#{application_path(applications(:pending))}']"
    assert_select "a[href='#{property_path(properties(:flat))}']", count: 0
  end

  test "hosts see links to their own properties" do
    act_as users(:host)
    get profile_path

    assert_response :success
    assert_select "a[href='#{property_path(properties(:flat))}']"
    assert_select "a[href='#{property_path(properties(:house))}']"
    assert_select "a[href='#{application_path(applications(:pending))}']", count: 0
  end

  test "profile editing is reachable from the user menu and has labeled fields" do
    act_as users(:seeker)
    get profile_path
    assert_select "nav a[href='#{profile_path}']", "Profile"
    assert_select "a[href='#{edit_profile_path}']", "Edit profile"

    get edit_profile_path
    assert_response :success
    assert_select "form[action='#{profile_path}']" do
      %w[name email_address phone bio password_challenge password password_confirmation].each do |field|
        assert_select "label[for=user_#{field}]"
      end
      assert_select "input#user_phone[type=tel]"
      assert_select "textarea#user_bio[maxlength='500']"
    end
  end

  test "members update their details without changing their password" do
    user = users(:seeker)
    act_as user
    digest = user.password_digest

    patch profile_path, params: { user: { name: "Sofía Pérez", email_address: " SOFIA.PEREZ@roomies.test ",
      phone: "+56 9 5550 3001", bio: "Student looking for a quiet home.",
      password: "", password_confirmation: "", password_challenge: "wrong" } }

    assert_redirected_to profile_path
    assert_equal "Your profile was updated.", flash[:notice]
    user.reload
    assert_equal "Sofía Pérez", user.name
    assert_equal "sofia.perez@roomies.test", user.email_address
    assert_equal "+56 9 5550 3001", user.phone
    assert_equal "Student looking for a quiet home.", user.bio
    assert_equal digest, user.password_digest
  end

  test "members cannot change roles, status or another user's profile" do
    user = users(:seeker)
    host = users(:host)
    act_as user

    assert_no_changes -> { host.reload.name } do
      patch profile_path, params: { id: host.id, user: { id: host.id, role: "moderator", status: "suspended", name: "My name" } }
    end

    assert_redirected_to profile_path
    assert user.reload.member?
    assert user.active?
    assert_equal "My name", user.name
  end

  test "invalid contact details and bio render field errors" do
    user = users(:seeker)
    act_as user

    assert_no_changes -> { user.reload.name } do
      patch profile_path, params: { user: { name: "Changed", email_address: users(:host).email_address,
        phone: "not a phone", bio: "a" * 501 } }
    end

    assert_response :unprocessable_entity
    assert_select "#email_address_error"
    assert_select "#phone_error"
    assert_select "#bio_error"
  end

  test "password changes require the current password even when the challenge param is missing" do
    user = users(:seeker)
    act_as user

    assert_no_changes -> { user.reload.password_digest } do
      patch profile_path, params: { user: { password: "newpassword123", password_confirmation: "newpassword123" } }
    end

    assert_response :unprocessable_entity
    assert_select "#password_challenge_error"
  end

  test "an incorrect current password prevents the update" do
    user = users(:seeker)
    act_as user

    assert_no_changes -> { user.reload.password_digest } do
      patch profile_path, params: { user: { password: "newpassword123", password_confirmation: "newpassword123",
        password_challenge: "wrong" } }
    end

    assert_response :unprocessable_entity
    assert_select "#password_challenge_error"
  end

  test "members change their password with the correct current password" do
    user = users(:seeker)
    act_as user

    patch profile_path, params: { user: { password: "newpassword123", password_confirmation: "newpassword123",
      password_challenge: "password123" } }

    assert_redirected_to profile_path
    assert user.reload.authenticate("newpassword123")
    assert_not user.authenticate("password123")

    get profile_path
    assert_response :success
  end

  test "password confirmation errors are shown in the profile form" do
    user = users(:seeker)
    act_as user

    assert_no_changes -> { user.reload.password_digest } do
      patch profile_path, params: { user: { password: "newpassword123", password_confirmation: "different123",
        password_challenge: "password123" } }
    end

    assert_response :unprocessable_entity
    assert_select "#password_confirmation_error"
  end
end
