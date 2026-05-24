# frozen_string_literal: true

require "test_helper"

module TwoStep
  class ConfigurationTest < ActiveSupport::TestCase
    test "defaults" do
      config = Configuration.new
      assert_equal "Rails App", config.issuer
      assert_equal 10, config.backup_code_count
      assert_equal 4, config.qr_code_module_size
      assert_equal 30, config.otp_drift_behind
      assert_equal 30, config.otp_drift_ahead
      assert_nil config.find_pending_resource({})
      assert_nil config.find_current_resource({})
      assert_equal "/", config.resolve_login_path
      assert_equal "/", config.resolve_after_two_step_login_path
      assert_equal "Rails App Security", config.resolve_layout_title
      assert_equal ["two_step/application"], config.resolve_layout_stylesheets
      assert_equal({lang: I18n.locale}, config.resolve_layout_html_attributes)
      assert_equal({class: "two_step-shell"}, config.resolve_layout_body_attributes)
      assert_equal "Rails App", config.resolve_layout_brand
    end

    test "configure returns configuration without a block" do
      assert_same TwoStep.configuration, TwoStep.configure
    end

    test "backup_code_digest_method and verify_method work together" do
      config = Configuration.new
      plain = BackupCodes.normalize("ABCD-EFGH-IJKL")
      hashed = config.backup_code_digest_method.call(plain)
      assert config.backup_code_verify_method.call(plain, hashed)
      assert_not config.backup_code_verify_method.call("WRONGCODE1234", hashed)
    end

    test "custom digest and verify methods" do
      config = Configuration.new
      config.backup_code_digest_method = ->(code) { Digest::SHA256.hexdigest(code) }
      config.backup_code_verify_method = ->(plain, hashed) {
        ActiveSupport::SecurityUtils.secure_compare(Digest::SHA256.hexdigest(plain), hashed)
      }
      plain = BackupCodes.normalize("WXYZ-2345-6789-ABCD")
      hashed = config.backup_code_digest_method.call(plain)
      assert config.backup_code_verify_method.call(plain, hashed)
    end

    test "on_authentication_success default is no-op" do
      config = Configuration.new
      assert_nothing_raised { config.run_authentication_success(nil, {}) }
    end

    test "configurable values support controller-aware callables and plain strings" do
      config = Configuration.new
      controller = Struct.new(:marker).new("controller")
      resource = Struct.new(:id).new(7)

      config.resource_finder = ->(session, current_controller) {
        [session[:user_id], current_controller.marker]
      }
      config.current_resource_finder = ->(session, current_controller) {
        [session[:user_id], current_controller.marker]
      }
      config.login_path = "/sign-in"
      config.after_two_step_login_path = lambda { |current_resource, current_controller|
        "/users/#{current_resource.id}?source=#{current_controller.marker}"
      }

      assert_equal [5, "controller"], config.find_pending_resource({user_id: 5}, controller: controller)
      assert_equal [5, "controller"], config.find_current_resource({user_id: 5}, controller: controller)
      assert_equal "/sign-in", config.resolve_login_path(controller: controller)
      assert_equal "/users/7?source=controller",
        config.resolve_after_two_step_login_path(resource, controller: controller)
    end

    test "run_authentication_success passes the controller when requested" do
      config = Configuration.new
      controller = Struct.new(:calls).new([])
      session = {}
      resource = Struct.new(:id).new(11)

      config.on_authentication_success = lambda { |current_resource, current_session, current_controller|
        current_controller.calls << :called
        current_session[:user_id] = current_resource.id
      }

      config.run_authentication_success(resource, session, controller: controller)

      assert_equal [:called], controller.calls
      assert_equal 11, session[:user_id]
    end

    test "layout values support callables, arrays, and hashes" do
      config = Configuration.new
      controller = Struct.new(:marker).new("main")

      config.layout_title = ->(current_controller) { "Secure #{current_controller.marker}" }
      config.layout_stylesheets = ->(current_controller) { ["two_step/application", "two_step/#{current_controller.marker}"] }
      config.layout_html_attributes = -> { {lang: "ja", data: {theme: "brand"}} }
      config.layout_body_attributes = -> { {class: "two_step-shell custom-shell"} }
      config.layout_brand = ->(current_controller) { "Brand #{current_controller.marker}" }

      assert_equal "Secure main", config.resolve_layout_title(controller: controller)
      assert_equal ["two_step/application", "two_step/main"], config.resolve_layout_stylesheets(controller: controller)
      assert_equal({lang: "ja", data: {theme: "brand"}}, config.resolve_layout_html_attributes)
      assert_equal({class: "two_step-shell custom-shell"}, config.resolve_layout_body_attributes)
      assert_equal "Brand main", config.resolve_layout_brand(controller: controller)
    end

    test "layout hash resolvers fall back to empty hashes on invalid values" do
      config = Configuration.new
      config.layout_html_attributes = "invalid"
      config.layout_body_attributes = -> { Object.new }

      assert_equal({}, config.resolve_layout_html_attributes)
      assert_equal({}, config.resolve_layout_body_attributes)
    end
  end
end
