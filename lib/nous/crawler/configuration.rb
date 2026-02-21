# frozen_string_literal: true

require "uri"

module Nous
  class Crawler < Command
    class Error < Command::Error; end

    class Configuration
      attr_reader :seed, :concurrency, :match, :limit, :timeout, :verbose, :keep_query

      DEFAULT_CONCURRENCY = 3
      DEFAULT_LIMIT = 100
      DEFAULT_TIMEOUT = 15

      def initialize(seed_url:, concurrency: DEFAULT_CONCURRENCY, match: [], limit: DEFAULT_LIMIT,
        timeout: DEFAULT_TIMEOUT, verbose: false, keep_query: false)
        @seed = parse_seed!(seed_url)
        @concurrency = Integer(concurrency).clamp(1, 20)
        @match = Array(match)
        @limit = Integer(limit).clamp(1, 10_000)
        @timeout = Integer(timeout)
        @verbose = verbose
        @keep_query = keep_query
      end

      private

      def parse_seed!(url)
        uri = URI.parse(url)
        raise Error, "seed URL must be http or https" unless uri.is_a?(URI::HTTP)

        uri
      rescue URI::InvalidURIError => e
        raise Error, "invalid seed URL: #{e.message}"
      end
    end
  end
end
