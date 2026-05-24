# frozen_string_literal: true

module TwoStep
  class Engine < ::Rails::Engine
    isolate_namespace TwoStep

    config.generators do |g|
      g.test_framework :test_unit
    end

    initializer "two_step.load_configuration", before: :load_config_initializers do
      # Host app configures via config/initializers/two_step.rb
    end
  end
end
