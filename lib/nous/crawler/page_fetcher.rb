# frozen_string_literal: true

module Nous
  class Crawler < Command
    class PageFetcher
      HTML_CONTENT_TYPES = %w[text/html application/xhtml+xml].freeze

      def initialize(client:, timeout:, verbose: false)
        @client = client
        @timeout = timeout
        @verbose = verbose
      end

      def fetch(url)
        Async::Task.current.with_timeout(timeout) do
          response = client.get(url, {})
          return skip(url, "status #{response.status}") unless response.status == 200
          return skip(url, "non-html content") unless html?(response)

          {url:, pathname: URI.parse(url).path, html: response.read}
        ensure
          response&.close
        end
      rescue Async::TimeoutError
        skip(url, "timeout after #{timeout}s")
      rescue IOError, SocketError, Errno::ECONNREFUSED => e
        skip(url, e.message)
      end

      private

      attr_reader :client, :timeout, :verbose

      def html?(response)
        content_type = response.headers["content-type"].to_s
        HTML_CONTENT_TYPES.any? { |type| content_type.include?(type) }
      end

      def skip(url, reason)
        warn("[nous] skip #{url}: #{reason}") if verbose
        nil
      end
    end
  end
end
