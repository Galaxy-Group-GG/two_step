# frozen_string_literal: true

if ENV["COVERAGE"]
  require "simplecov"
  require "simplecov-lcov"

  SimpleCov::Formatter::LcovFormatter.config do |config|
    config.report_with_single_file = true
    config.single_report_path = "coverage/lcov.info"
  end

  SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter
  ])

  SimpleCov.start do
    enable_coverage :branch
    minimum_coverage 100
    minimum_coverage_by_file 100
    add_filter "/test/dummy/"
    add_filter "/test/"
    add_filter "/lib/generators/"
    add_filter "/lib/two_step/version.rb"
    track_files "{app,lib}/**/*.rb"
  end
end

ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [
  File.expand_path("dummy/db/migrate", __dir__)
]
require "rails/test_help"
require "rails/generators/test_case"

module ActiveSupport
  class TestCase
    parallelize(workers: 1)

    self.use_transactional_tests = true

    setup do
      TwoStep.reset_configuration!
      configure_two_step_defaults
    end

    def configure_two_step_defaults
      TwoStep.configure do |config|
        config.issuer = "TestApp"
        config.resource_finder = ->(session) { User.find_by(id: session[:two_step_pending_user_id]) }
        config.current_resource_finder = ->(session) { User.find_by(id: session[:user_id]) }
        config.login_path = "/login"
        config.after_two_step_login_path = "/"
        config.on_authentication_success = ->(resource, session, _controller) {
          session.delete(:two_step_pending_user_id)
          session[:user_id] = resource.id
        }
      end
    end
  end
end
