# frozen_string_literal: true

require "bundler/setup"

APP_RAKEFILE = File.expand_path("test/dummy/Rakefile", __dir__)
load "rails/tasks/engine.rake"

require "bundler/gem_tasks"

desc "Run the engine test suite"
task :test do
  if ENV["COVERAGE"]
    Rake::Task["coverage"].invoke
  else
    Rake::Task["app:test"].invoke
  end
end

desc "Run tests with SimpleCov (100% threshold)"
task :coverage do
  ENV["COVERAGE"] = "1"

  sh(
    "bundle",
    "exec",
    "ruby",
    "-Itest",
    "-e",
    'Dir["test/**/*_test.rb"].sort.each { |file| require File.expand_path(file) }'
  )
end
