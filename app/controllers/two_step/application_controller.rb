# frozen_string_literal: true

module TwoStep
  # Base for all engine controllers. Namespace isolation keeps routes, helpers,
  # and constants separate from the host application (see TwoStep::Engine).
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
  end
end
