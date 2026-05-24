# frozen_string_literal: true

class AddTwoStepToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :otp_secret, :string
    add_column :users, :otp_required_for_login, :boolean, default: false, null: false
    add_column :users, :otp_backup_codes, :text
    add_column :users, :last_otp_at, :integer
  end
end
