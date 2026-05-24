# frozen_string_literal: true

TwoStep::Engine.routes.draw do
  resource :two_step_challenge, only: %i[new create], path: "challenge"
  resource :two_step_setup, only: %i[new create], path: "setup" do
    post :disable, on: :member
  end
end
