# frozen_string_literal: true

require "digest"

module TwoStep
  class Configuration
    attr_accessor :issuer,
      :backup_code_count,
      :qr_code_module_size,
      :otp_drift_behind,
      :otp_drift_ahead,
      :resource_finder,
      :current_resource_finder,
      :login_path,
      :after_two_step_login_path,
      :on_authentication_success,
      :backup_code_digest_method,
      :backup_code_verify_method,
      :layout_title,
      :layout_stylesheets,
      :layout_html_attributes,
      :layout_body_attributes,
      :layout_brand

    def initialize
      @issuer = "Rails App"
      @backup_code_count = 10
      @qr_code_module_size = 4
      @otp_drift_behind = 30
      @otp_drift_ahead = 30
      @resource_finder = ->(*) {}
      @current_resource_finder = ->(*) {}
      @login_path = "/"
      @after_two_step_login_path = "/"
      @on_authentication_success = ->(*) {}
      @layout_title = -> { "#{issuer} Security" }
      @layout_stylesheets = ["two_step/application"]
      @layout_html_attributes = -> { {lang: I18n.locale} }
      @layout_body_attributes = {class: "two_step-shell"}
      @layout_brand = -> { issuer }

      # Switched to SHA256 for O(1) performance during generation.
      # Because the backup codes are 15 characters of high-entropy randomness,
      # a slow-hash like BCrypt is unnecessary and harms user experience.
      @backup_code_digest_method = ->(normalized_code) {
        Digest::SHA256.hexdigest(normalized_code)
      }
      @backup_code_verify_method = ->(normalized_code, hashed) {
        Rack::Utils.secure_compare(Digest::SHA256.hexdigest(normalized_code), hashed)
      }
    end

    def find_pending_resource(session, controller: nil)
      resolve_callable(resource_finder, session, controller)
    end

    def find_current_resource(session, controller: nil)
      resolve_callable(current_resource_finder, session, controller)
    end

    def resolve_login_path(controller: nil)
      resolve_callable(login_path, controller)
    end

    def resolve_after_two_step_login_path(resource = nil, controller: nil)
      resolve_callable(after_two_step_login_path, resource, controller)
    end

    def run_authentication_success(resource, session, controller: nil)
      resolve_callable(on_authentication_success, resource, session, controller)
    end

    def resolve_layout_title(controller: nil)
      resolve_callable(layout_title, controller)
    end

    def resolve_layout_stylesheets(controller: nil)
      Array(resolve_callable(layout_stylesheets, controller)).flatten.compact
    end

    def resolve_layout_html_attributes(controller: nil)
      resolve_hash(resolve_callable(layout_html_attributes, controller))
    end

    def resolve_layout_body_attributes(controller: nil)
      resolve_hash(resolve_callable(layout_body_attributes, controller))
    end

    def resolve_layout_brand(controller: nil)
      resolve_callable(layout_brand, controller)
    end

    private

    def resolve_callable(value, *args)
      return value unless value.respond_to?(:call)

      # Simplified and safer arity handling
      arity = value.arity
      if arity >= 0
        value.call(*args.take(arity))
      else
        # For variable length (*args) or unspecified blocks, pass everything
        value.call(*args)
      end
    end

    def resolve_hash(value)
      value.to_h
    rescue
      {}
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
      configuration
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
