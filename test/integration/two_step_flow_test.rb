# frozen_string_literal: true

require "test_helper"

class TwoStepFlowTest < ActionDispatch::IntegrationTest
  include TwoStep::Engine.routes.url_helpers

  setup do
    @user = User.create!(email: "flow@example.com")
  end

  test "full setup and challenge flow via HTTP" do
    sign_in(@user)
    get new_two_step_setup_path
    assert_response :success

    post two_step_setup_path, params: {otp_code: ROTP::TOTP.new(@user.reload.otp_secret).now}
    assert_response :success
    assert @user.reload.otp_required_for_login?

    sign_in_pending(@user)
    travel 31.seconds do
      post two_step_challenge_path, params: {otp_code: ROTP::TOTP.new(@user.otp_secret).now}
      assert_redirected_to "/"
    end
  end

  test "challenge redirect when unauthenticated" do
    get new_two_step_challenge_path
    assert_redirected_to "/login"
  end

  test "setup redirect when unauthenticated" do
    get new_two_step_setup_path
    assert_redirected_to "/login"
  end

  test "disable via member route" do
    @user.generate_otp_secret!
    @user.update!(otp_required_for_login: true)
    sign_in(@user)
    post disable_two_step_setup_path
    assert_redirected_to "/"
    assert_not @user.reload.otp_required_for_login?
  end

  private

  def sign_in(user)
    post "/test/session", params: {user_id: user.id}
  end

  def sign_in_pending(user)
    post "/test/session", params: {two_step_pending_user_id: user.id}
  end
end
