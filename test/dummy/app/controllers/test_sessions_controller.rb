# frozen_string_literal: true

class TestSessionsController < ApplicationController
  def create
    session[:user_id] = params[:user_id]
    session[:two_step_pending_user_id] = params[:two_step_pending_user_id] if params[:two_step_pending_user_id].present?
    head :ok
  end
end
