# frozen_string_literal: true

class User < ApplicationRecord
  include TwoStep::Models::Authenticatable
end
