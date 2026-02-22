# frozen_string_literal: true

module Nous
  class Configuration
    attr_reader :concurrency, :match, :limit, :timeout, :keep_query

    DEFAULT_CONCURRENCY = 3
    DEFAULT_LIMIT = 100
    DEFAULT_TIMEOUT = 15

    def initialize(concurrency: DEFAULT_CONCURRENCY, match: [], limit: DEFAULT_LIMIT,
      timeout: DEFAULT_TIMEOUT, debug: false, keep_query: false)
      @concurrency = Integer(concurrency).clamp(1, 20)
      @match = Array(match)
      @limit = Integer(limit).clamp(1, 10_000)
      @timeout = Integer(timeout)
      @debug = debug
      @keep_query = keep_query
    end

    def debug? = @debug
  end
end
