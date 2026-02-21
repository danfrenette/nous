# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"

module Nous
  class Extractor
    class Jina
      class Client
        class Error < Nous::Error; end

        BASE_URL = "https://r.jina.ai"
        RETRYABLE_STATUSES = [429, 500, 502, 503, 504].freeze
        MAX_RETRIES = 3

        def initialize(api_key: nil, timeout: 30, retry_interval: 1)
          @connection = build_connection(api_key:, timeout:, retry_interval:)
        end

        def get(url)
          response = connection.get("/#{url}")
          parse(response.body)
        rescue Faraday::Error => e
          raise Error, e.message
        end

        private

        attr_reader :connection

        def build_connection(api_key:, timeout:, retry_interval:)
          Faraday.new(url: BASE_URL) do |f|
            f.response :raise_error

            f.request :retry,
              max: MAX_RETRIES,
              interval: retry_interval,
              backoff_factor: 2,
              retry_statuses: RETRYABLE_STATUSES

            f.headers["Accept"] = "application/json"
            f.headers["X-No-Cache"] = "true"
            f.headers["Authorization"] = "Bearer #{api_key}" if api_key

            f.options.timeout = timeout
            f.options.open_timeout = timeout
          end
        end

        def parse(body)
          JSON.parse(body)
        rescue JSON::ParserError => e
          raise Error, "invalid JSON: #{e.message}"
        end
      end
    end
  end
end
