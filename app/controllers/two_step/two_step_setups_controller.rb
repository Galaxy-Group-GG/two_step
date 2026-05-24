# frozen_string_literal: true

module TwoStep
  class TwoStepSetupsController < ApplicationController
    before_action :require_setup_resource, only: %i[new create]
    before_action :require_current_resource, only: :disable

    helper_method :current_resource, :setup_resource, :setup_requires_login_challenge?

    def new
      setup_resource.ensure_otp_secret!
      @qr_svg = generate_qr_svg(setup_resource.otp_provisioning_uri)
    end

    def create
      if setup_resource.verify_otp(params[:otp_code])
        setup_resource.update_columns(otp_required_for_login: true)
        @backup_codes = setup_resource.generate_backup_codes!

        if setup_requires_login_challenge?
          TwoStep.configuration.run_authentication_success(setup_resource, session, controller: self)
        end

        render :complete
      else
        flash.now[:alert] = I18n.t("two_step.setups.invalid_otp")
        @qr_svg = generate_qr_svg(setup_resource.otp_provisioning_uri)
        render :new, status: :unprocessable_content
      end
    end

    def disable
      current_resource.disable_otp!
      redirect_to(
        disable_redirect_path || TwoStep.configuration.resolve_after_two_step_login_path(current_resource, controller: self),
        notice: I18n.t("two_step.setups.disabled")
      )
    end

    private

    def current_resource
      @current_resource ||= TwoStep.configuration.find_current_resource(session, controller: self)
    end

    def setup_resource
      @setup_resource ||= current_resource || TwoStep.configuration.find_pending_resource(session, controller: self)
    end

    def setup_requires_login_challenge?
      setup_resource.present? && current_resource.blank?
    end

    def require_setup_resource
      redirect_to TwoStep.configuration.resolve_login_path(controller: self) unless setup_resource
    end

    def require_current_resource
      redirect_to TwoStep.configuration.resolve_login_path(controller: self) unless current_resource
    end

    def generate_qr_svg(uri)
      RQRCode::QRCode.new(uri).as_svg(
        module_size: TwoStep.configuration.qr_code_module_size,
        standalone: true,
        use_path: true
      ).html_safe
    end

    def disable_redirect_path
      candidate = params[:return_to].to_s
      return if candidate.blank?
      return if !candidate.start_with?("/") || candidate.start_with?("//")

      candidate
    end
  end
end
