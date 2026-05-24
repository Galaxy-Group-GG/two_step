# frozen_string_literal: true

require "rails/generators/active_record"

module TwoStep
  class InstallGenerator < Rails::Generators::Base
    include ActiveRecord::Generators::Migration

    source_root File.expand_path("templates", __dir__)

    class_option :model, type: :string, default: "User", desc: "Model name (e.g. User, Admin)"

    desc "Adds TwoStep columns and initializer"

    def create_migration_file
      migration_template(
        "migration.rb.erb",
        "db/migrate/add_two_step_to_#{table_name}.rb",
        migration_version: migration_version
      )
    end

    def create_initializer
      template "initializer.rb.erb", "config/initializers/two_step.rb"
    end

    def show_readme
      say "Add to your #{model} model:", :green
      say "  include TwoStep::Models::Authenticatable"
      say "  encrypts :otp_secret  # recommended (Rails 7+)"
    end

    private

    def table_name
      model.underscore.pluralize
    end

    def model
      options[:model]
    end

    def migration_version
      "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
    end
  end
end
