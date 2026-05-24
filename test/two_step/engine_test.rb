# frozen_string_literal: true

require "test_helper"

module TwoStep
  class EngineTest < ActiveSupport::TestCase
    test "engine isolates namespace" do
      assert_equal TwoStep, Engine.railtie_namespace
      assert Engine.isolated?
      assert_equal "two_step", Engine.engine_name
    end

    test "engine loads" do
      assert Rails.application.railties.any? { |r| r.is_a?(TwoStep::Engine) }
    end
  end
end
