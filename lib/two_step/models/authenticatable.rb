# frozen_string_literal: true

require "active_support/concern"
require "rotp"

module TwoStep
  module Models
    module Authenticatable
      extend ActiveSupport::Concern

      included do
        serialize :otp_backup_codes, coder: JSON
      end

      def otp_enabled?
        otp_required_for_login? && otp_secret.present?
      end

      def generate_otp_secret!
        # update_columns avoids instantiation overhead and bypasses unrelated model validations
        update_columns(otp_secret: ROTP::Base32.random, last_otp_at: nil)
      end

      def ensure_otp_secret!
        return otp_secret if otp_secret.present?

        generate_otp_secret!
        otp_secret
      end

      def otp_provisioning_uri(account_label = nil)
        raise ArgumentError, "otp_secret is blank" if otp_secret.blank?

        label = (account_label || (respond_to?(:email) ? email : id)).to_s
        build_totp.provisioning_uri(label)
      end

      def current_otp
        build_totp.now if otp_secret.present?
      end

      def verify_otp(code)
        return false if otp_secret.blank? || code.blank?

        timestamp = verified_otp_timestamp(code)
        return false unless timestamp
        return false if last_otp_at.present? && last_otp_at >= timestamp

        update_column(:last_otp_at, timestamp)
        true
      end

      def generate_backup_codes!
        codes = BackupCodes.generate
        hashed_codes = codes.map { |plain| digest_backup_code(plain) }

        update_columns(otp_backup_codes: hashed_codes)
        codes
      end

      def consume_backup_code(code)
        normalized = BackupCodes.normalize(code)
        return false if normalized.blank?

        # Stored codes are automatically parsed as an Array via `serialize`
        stored = Array(otp_backup_codes)
        return false if stored.empty?

        index = stored.index { |hashed| backup_code_matches?(normalized, hashed) }
        return false unless index

        stored.delete_at(index)
        update_columns(otp_backup_codes: stored.empty? ? nil : stored)
        true
      end

      def disable_otp!
        update_columns(
          otp_secret: nil,
          otp_required_for_login: false,
          otp_backup_codes: nil,
          last_otp_at: nil
        )
      end

      private

      def build_totp
        ROTP::TOTP.new(otp_secret, issuer: TwoStep.configuration.issuer)
      end

      def verified_otp_timestamp(code)
        build_totp.verify(
          code.to_s.strip,
          drift_behind: TwoStep.configuration.otp_drift_behind,
          drift_ahead: TwoStep.configuration.otp_drift_ahead
        )
      end

      def digest_backup_code(code)
        TwoStep.configuration.backup_code_digest_method.call(BackupCodes.normalize(code))
      end

      def backup_code_matches?(normalized_code, hashed_code)
        TwoStep.configuration.backup_code_verify_method.call(normalized_code, hashed_code)
      end
    end
  end
end
