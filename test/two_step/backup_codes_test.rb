# frozen_string_literal: true

require "test_helper"

module TwoStep
  class BackupCodesTest < ActiveSupport::TestCase
    test "generate_one returns grouped alphanumeric code" do
      code = BackupCodes.generate_one
      assert_match(/\A[A-Z2-9]{3}(-[A-Z2-9]{3}){4}\z/, code)
      assert_not_includes code, "O"
      assert_not_includes code, "I"
    end

    test "normalize strips hyphens and spaces" do
      assert_equal "ABCDEFGHIJKL", BackupCodes.normalize("abcd-efgh-ijkl")
      assert_equal "ABCDEFGHIJKL", BackupCodes.normalize("  abcd efgh ijkl  ")
    end

    test "generate returns configured count" do
      TwoStep.configure { |c| c.backup_code_count = 3 }
      assert_equal 3, BackupCodes.generate.length
    end
  end
end
