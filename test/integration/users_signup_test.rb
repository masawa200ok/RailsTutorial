require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest

  def setup
    ActionMailer::Base.deliveries.clear
  end

  test "invalid signup information" do
    get signup_path
    assert_no_difference "User.count" do
      post users_path, params: {
        user: {
          name: "",
          email: "user@invalid",
          password: "foo",
          password_confirmation: "bar"
        }
      }
    end
    assert_template "users/new"

    assert_select "div#error_explanation"
    assert_select "div.alert"
    #assert_select 'form[action="/signup"]'
    assert_select 'form[action="/users"]'

    assert_not flash[:success]
  end

  test "valid signup information" do
    get signup_url
    assert_difference "User.count", 1 do
      post users_path, params: { user: {
          name: "Example User",
          email: "user@example.com",
          password: "password",
          password_confirmation: "password"
        }
      }
    end
    follow_redirect!
    
    # TODO
    #assert_template "users/show"
    #assert flash[:success]
  end

  test "valid signup information with account activation" do
    get signup_path
    assert_difference "User.count", 1 do
      post users_path, params: { user: {
          name: "Example User",
          email: "user@example.com",
          password: "password",
          password_confirmation: "password"
      }}
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
    user = assigns(:user)
    assert_not user.activated?
    log_in_as(user)
    assert_not is_logged_in?
    get edit_account_activation_path("invalid_token", email: user.email)
    get edit_account_activation_path(user.activation_token, email: "wrong")
    assert_not is_logged_in?
    get edit_account_activation_path(user.activation_token, email: user.email)
    assert user.reload.activated?
    follow_redirect!
    assert_template "users/show"
    assert is_logged_in?
  end

end
