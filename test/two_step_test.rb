# frozen_string_literal: true

require "test_helper"

class TwoStepTest < ActiveSupport::TestCase
  test "version is present" do
    assert_equal "1.0.0", TwoStep::VERSION
  end

  test "configure yields configuration" do
    TwoStep.configure do |config|
      config.issuer = "Custom"
    end
    assert_equal "Custom", TwoStep.configuration.issuer
  end

  test "reset_configuration restores defaults" do
    TwoStep.configure { |c| c.issuer = "X" }
    TwoStep.reset_configuration!
    assert_equal "Rails App", TwoStep.configuration.issuer
  end
end
