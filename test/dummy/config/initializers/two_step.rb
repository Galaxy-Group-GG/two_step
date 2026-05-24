# frozen_string_literal: true

TwoStep.configure do |config|
  config.issuer = "Dummy"

  config.resource_finder = ->(session) {
    User.find_by(id: session[:two_step_pending_user_id])
  }

  config.current_resource_finder = ->(session) {
    User.find_by(id: session[:user_id])
  }

  config.login_path = "/login"
  config.after_two_step_login_path = "/"

  config.on_authentication_success = ->(resource, session, _controller) {
    session.delete(:two_step_pending_user_id)
    session[:user_id] = resource.id
    session[:two_step_completed] = true
  }
end
