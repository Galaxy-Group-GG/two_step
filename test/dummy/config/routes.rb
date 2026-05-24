Rails.application.routes.draw do
  mount TwoStep::Engine => "/two_step"

  post "/test/session", to: "test_sessions#create"
end
