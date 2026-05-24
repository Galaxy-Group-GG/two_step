# frozen_string_literal: true

require "securerandom"

module TwoStep
  module BackupCodes
    extend self

    CHARSET = (("A".."Z").to_a + ("2".."9").to_a - %w[I L O]).freeze

    # 5 segments (15 chars total) to provide ~74 bits of entropy.
    SEGMENT_COUNT = 5
    SEGMENT_LENGTH = 3

    def generate_one
      SEGMENT_COUNT.times.map { random_segment }.join("-")
    end

    def generate(count: TwoStep.configuration.backup_code_count)
      Array.new(count) { generate_one }
    end

    def normalize(code)
      code.to_s.strip.upcase.gsub(/[^A-Z2-9]/, "")
    end

    private

    def random_segment
      SEGMENT_LENGTH.times.map { CHARSET.sample(random: SecureRandom) }.join
    end
  end
end
