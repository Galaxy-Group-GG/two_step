# frozen_string_literal: true

require "test_helper"

module TwoStep
  class TwoStepSetupsControllerTest < ActionController::TestCase
    tests TwoStepSetupsController

    setup do
      @routes = TwoStep::Engine.routes
      @user = User.create!(email: "setup@example.com")
      @request.session[:user_id] = @user.id
    end

    test "new generates secret and renders qr" do
      get :new
      assert_response :success
      assert @user.reload.otp_secret.present?
      assert_select "svg"
    end

    test "new redirects without logged-in user" do
      @request.session[:user_id] = nil
      get :new
      assert_redirected_to "/login"
    end

    test "new does not rotate an existing secret" do
      @user.generate_otp_secret!
      @user.update!(otp_required_for_login: true)
      original_secret = @user.reload.otp_secret

      get :new

      assert_response :success
      assert_equal original_secret, @user.reload.otp_secret
    end

    test "create enables two_step and shows backup codes" do
      @user.generate_otp_secret!
      post :create, params: {otp_code: @user.current_otp}
      assert_response :success
      assert @user.reload.otp_required_for_login?
      assert_select "code", minimum: 10
    end

    test "create completes pending setup and signs the user in" do
      @request.session[:user_id] = nil
      @request.session[:two_step_pending_user_id] = @user.id
      @user.generate_otp_secret!

      post :create, params: {otp_code: @user.current_otp}

      assert_response :success
      assert @user.reload.otp_required_for_login?
      assert_equal @user.id, @request.session[:user_id]
      assert_nil @request.session[:two_step_pending_user_id]
    end

    test "create re-renders new on invalid otp" do
      @user.generate_otp_secret!
      post :create, params: {otp_code: "000000"}
      assert_response :unprocessable_entity
      assert_select "svg"
    end

    test "disable clears two_step" do
      @user.generate_otp_secret!
      @user.update!(otp_required_for_login: true)
      post :disable
      assert_redirected_to "/"
      assert_not @user.reload.otp_required_for_login?
    end

    test "disable redirects without logged-in user" do
      @request.session[:user_id] = nil

      post :disable

      assert_redirected_to "/login"
    end

    test "disable redirects to a safe return_to path" do
      @user.generate_otp_secret!
      @user.update!(otp_required_for_login: true)

      post :disable, params: {return_to: "/settings/security"}

      assert_redirected_to "/settings/security"
    end

    test "disable ignores an unsafe return_to path" do
      @user.generate_otp_secret!
      @user.update!(otp_required_for_login: true)

      post :disable, params: {return_to: "https://example.com/phish"}

      assert_redirected_to "/"
    end
  end
end
