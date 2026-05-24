# frozen_string_literal: true

require "test_helper"

module TwoStep
  module Models
    class AuthenticatableTest < ActiveSupport::TestCase
      setup do
        @user = User.create!(email: "user@example.com")
      end

      test "otp_enabled? reflects required flag and secret" do
        assert_not @user.otp_enabled?
        @user.update!(otp_secret: ROTP::Base32.random, otp_required_for_login: true)
        assert @user.otp_enabled?
      end

      test "generate_otp_secret! persists secret" do
        @user.generate_otp_secret!
        assert @user.otp_secret.present?
      end

      test "ensure_otp_secret! keeps an existing secret" do
        @user.generate_otp_secret!
        original_secret = @user.otp_secret

        @user.ensure_otp_secret!

        assert_equal original_secret, @user.reload.otp_secret
      end

      test "otp_provisioning_uri requires secret" do
        assert_raises(ArgumentError) { @user.otp_provisioning_uri }
        @user.generate_otp_secret!
        uri = @user.otp_provisioning_uri
        assert_includes uri, "otpauth://"
        assert_includes uri, CGI.escape(TwoStep.configuration.issuer)
      end

      test "otp_provisioning_uri uses email label when available" do
        @user.generate_otp_secret!
        assert_includes @user.otp_provisioning_uri, CGI.escape(@user.email)
      end

      test "otp_provisioning_uri falls back to id when email is unavailable" do
        resource_class = Class.new do
          def self.serialize(*)
          end

          include TwoStep::Models::Authenticatable

          attr_reader :id, :otp_secret

          def initialize(id:, otp_secret:)
            @id = id
            @otp_secret = otp_secret
          end
        end

        resource = resource_class.new(id: 42, otp_secret: ROTP::Base32.random)

        assert_includes resource.otp_provisioning_uri, "42"
      end

      test "current_otp returns nil without secret" do
        assert_nil @user.current_otp
      end

      test "verify_otp accepts valid code and prevents replay" do
        @user.generate_otp_secret!
        code = @user.current_otp
        assert @user.verify_otp(code)
        assert_not @user.verify_otp(code)
      end

      test "verify_otp rejects blank code and secret" do
        assert_not @user.verify_otp("123456")
        @user.generate_otp_secret!
        assert_not @user.verify_otp("")
        assert_not @user.verify_otp("000000")
      end

      test "generate_backup_codes! stores hashed codes and returns grouped plaintext" do
        @user.generate_otp_secret!
        codes = @user.generate_backup_codes!
        assert_equal 10, codes.length
        codes.each { |code| assert_match(/\A[A-Z2-9]{3}(-[A-Z2-9]{3}){4}\z/, code) }
        stored = Array(@user.reload.otp_backup_codes)
        assert_equal 10, stored.length
        codes.each do |plain|
          normalized = BackupCodes.normalize(plain)
          assert stored.any? { |h| TwoStep.configuration.backup_code_verify_method.call(normalized, h) }
        end
      end

      test "consume_backup_code accepts code without hyphens" do
        @user.generate_otp_secret!
        codes = @user.generate_backup_codes!
        ungrouped = BackupCodes.normalize(codes.first)
        assert @user.consume_backup_code(ungrouped)
      end

      test "consume_backup_code removes one code" do
        @user.generate_otp_secret!
        codes = @user.generate_backup_codes!
        assert @user.consume_backup_code(codes.first)
        assert_not @user.consume_backup_code(codes.first)
        assert @user.consume_backup_code(codes.second)
      end

      test "consume_backup_code rejects blank input" do
        @user.generate_otp_secret!
        @user.generate_backup_codes!
        assert_not @user.consume_backup_code("")
        @user.update!(otp_backup_codes: nil)
        assert_not @user.consume_backup_code("abcd")
      end

      test "consume_backup_code fails closed when stored data is malformed" do
        @user.generate_otp_secret!
        @user.update!(otp_backup_codes: "not-json")

        assert_not @user.consume_backup_code("abcd-efgh-ijkl")
      end

      test "consume_backup_code fails closed when stored data is not an array" do
        @user.generate_otp_secret!
        @user.update!(otp_backup_codes: {code: "value"}.to_json)

        assert_not @user.consume_backup_code("abcd-efgh-ijkl")
      end

      test "consume_backup_code clears column when last code used" do
        @user.generate_otp_secret!
        TwoStep.configure { |c| c.backup_code_count = 1 }
        code = @user.generate_backup_codes!.first
        assert @user.consume_backup_code(code)
        assert_nil @user.reload.otp_backup_codes
      end

      test "disable_otp! clears all otp fields" do
        @user.generate_otp_secret!
        @user.update!(otp_required_for_login: true, last_otp_at: 1)
        @user.generate_backup_codes!
        @user.disable_otp!
        @user.reload
        assert_nil @user.otp_secret
        assert_not @user.otp_required_for_login
        assert_nil @user.otp_backup_codes
        assert_nil @user.last_otp_at
      end
    end
  end
end
