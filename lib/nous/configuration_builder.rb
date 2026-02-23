# frozen_string_literal: true

module Nous
  class ConfigurationBuilder
    class UnknownOptionError < StandardError; end

    DEFAULTS = {
      concurrency: 3,
      match: [],
      limit: 100,
      timeout: 15,
      debug: false,
      keep_query: false,
      recursive: false
    }.freeze

    def self.call(**options)
      new(options).call
    end

    def initialize(options)
      @options = options
    end

    def call
      validate_keys!

      Configuration.new(**coerced_options)
    end

    private

    attr_reader :options

    def validate_keys!
      unknown = options.keys - Configuration.members
      return if unknown.empty?

      raise UnknownOptionError, "unknown option(s): #{unknown.join(", ")}"
    end

    def coerced_options
      merged = DEFAULTS.merge(options)

      {
        concurrency: Integer(merged[:concurrency]).clamp(1, 20),
        match: Array(merged[:match]),
        limit: Integer(merged[:limit]).clamp(1, 10_000),
        timeout: Integer(merged[:timeout]),
        debug: !!merged[:debug],
        keep_query: !!merged[:keep_query],
        recursive: !!merged[:recursive]
      }
    end
  end
end
