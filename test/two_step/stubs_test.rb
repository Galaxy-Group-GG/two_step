# frozen_string_literal: true

require "test_helper"

module TwoStep
  class StubsTest < ActiveSupport::TestCase
    test "application record is abstract" do
      assert ApplicationRecord.abstract_class
    end

    test "application mailer default from" do
      assert_equal "from@example.com", ApplicationMailer.default[:from]
    end

    test "application job inherits ActiveJob" do
      assert ApplicationJob < ActiveJob::Base
    end

    test "application helper module exists" do
      assert_kind_of Module, ApplicationHelper
    end

    test "application controller uses exception-based forgery protection" do
      assert_equal(
        ActionController::RequestForgeryProtection::ProtectionMethods::Exception,
        ApplicationController.forgery_protection_strategy
      )
    end
  end
end
