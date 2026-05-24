# frozen_string_literal: true

require "test_helper"
require "generators/two_step/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests TwoStep::InstallGenerator
  destination Rails.root.join("tmp/generator_test")
  setup :prepare_destination

  test "generates migration and initializer" do
    run_generator ["--model=User"]
    assert_migration "db/migrate/add_two_step_to_users.rb"
    assert_file "config/initializers/two_step.rb", /TwoStep.configure/
    assert_file "config/initializers/two_step.rb", /User\.find_by/
  end

  test "generates migration for custom model" do
    run_generator ["--model=Admin"]
    assert_migration "db/migrate/add_two_step_to_admins.rb"
    assert_file "config/initializers/two_step.rb", /Admin\.find_by/
  end
end
