# frozen_string_literal: true

module TwoStep
  class TwoStepChallengesController < ApplicationController
    before_action :require_pending_resource

    def new
    end

    def create
      resource = pending_resource
      if params[:backup_code].present?
        verify_backup(resource)
      else
        verify_otp(resource)
      end
    end

    private

    def verify_backup(resource)
      if resource.consume_backup_code(params[:backup_code])
        complete_two_step(resource)
      else
        flash.now[:alert] = I18n.t("two_step.challenges.invalid_backup")
        render :new, status: 422
      end
    end

    def verify_otp(resource)
      if resource.verify_otp(params[:otp_code])
        complete_two_step(resource)
      else
        flash.now[:alert] = I18n.t("two_step.challenges.invalid_otp")
        render :new, status: 422
      end
    end

    def pending_resource
      @pending_resource ||= TwoStep.configuration.find_pending_resource(session, controller: self)
    end

    def require_pending_resource
      redirect_to TwoStep.configuration.resolve_login_path(controller: self) unless pending_resource
    end

    def complete_two_step(resource)
      TwoStep.configuration.run_authentication_success(resource, session, controller: self)
      redirect_to TwoStep.configuration.resolve_after_two_step_login_path(resource, controller: self)
    end
  end
end
