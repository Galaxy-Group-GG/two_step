# frozen_string_literal: true

require "test_helper"

module TwoStep
  class TwoStepChallengesControllerTest < ActionController::TestCase
    tests TwoStepChallengesController

    setup do
      @routes = TwoStep::Engine.routes
      @user = User.create!(email: "challenge@example.com")
      @user.generate_otp_secret!
      @user.update!(otp_required_for_login: true)
      @request.session[:two_step_pending_user_id] = @user.id
    end

    test "new renders" do
      get :new
      assert_response :success
    end

    test "new uses layout overrides from configuration" do
      TwoStep.configure do |config|
        config.layout_title = "Custom Security"
        config.layout_stylesheets = ["two_step/application", "two_step/host"]
        config.layout_html_attributes = {lang: "ja", data: {theme: "host"}}
        config.layout_body_attributes = {class: "two_step-shell host-shell", data: {screen: "challenge"}}
        config.layout_brand = "Host Brand"
      end

      get :new

      assert_response :success
      assert_select "html[lang='ja'][data-theme='host']"
      assert_select "title", text: "Custom Security"
      assert_select "link[href*='two_step/application']", count: 1
      assert_select "link[href*='two_step/host']", count: 1
      assert_select "body.two_step-shell.host-shell[data-screen='challenge']"
      assert_select "p.two_step-brand", text: "Host Brand"
    end

    test "new redirects without pending resource" do
      @request.session[:two_step_pending_user_id] = nil
      get :new
      assert_redirected_to "/login"
    end

    test "create succeeds with valid otp" do
      post :create, params: {otp_code: @user.current_otp}
      assert_redirected_to "/"
      assert_equal @user.id, @request.session[:user_id]
      assert_nil @request.session[:two_step_pending_user_id]
    end

    test "create fails with invalid otp" do
      post :create, params: {otp_code: "000000"}
      assert_response :unprocessable_entity
      assert_select "h1", text: /Two-Factor/i
    end

    test "create succeeds with backup code" do
      codes = @user.generate_backup_codes!
      post :create, params: {backup_code: codes.first}
      assert_redirected_to "/"
    end

    test "create fails with invalid backup code" do
      @user.generate_backup_codes!
      post :create, params: {backup_code: "invalid"}
      assert_response :unprocessable_entity
    end
  end
end
