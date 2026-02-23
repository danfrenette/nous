# frozen_string_literal: true

module Nous
  class Crawler < Command
    class AsyncPageFetcher
      HTML_CONTENT_TYPES = %w[text/html application/xhtml+xml].freeze

      def initialize(client:, seed_host:)
        @client = client
        @seed_host = seed_host
      end

      def fetch(url)
        Async::Task.current.with_timeout(config.timeout) do
          result = RedirectFollower.call(client:, seed_host:, url:)
          return skip(url, result.error.message) if result.failure?

          response, final_url = result.payload
          return skip(url, "status #{response.status}") unless response.status == 200
          return skip(url, "non-html content") unless html?(response)

          RawPage.new(url: final_url.to_s, pathname: final_url.path, html: response.read)
        ensure
          response&.close
        end
      rescue Async::TimeoutError
        skip(url, "timeout after #{config.timeout}s")
      rescue IOError, SocketError, Errno::ECONNREFUSED => e
        skip(url, e.message)
      end

      private

      attr_reader :client, :seed_host

      def config
        Nous.configuration
      end

      def html?(response)
        content_type = response.headers["content-type"].to_s
        HTML_CONTENT_TYPES.any? { |type| content_type.include?(type) }
      end

      def skip(url, reason)
        warn("[nous] skip #{url}: #{reason}") if config.debug?
        nil
      end
    end
  end
end
