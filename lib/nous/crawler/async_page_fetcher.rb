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
          return build_failed_record(url, result.error.message) if result.failure?

          response, final_url = result.payload
          content_type = response.headers["content-type"].to_s
          redirected = final_url.to_s != url

          return build_failed_record(url, "status #{response.status}") unless response.status == 200
          return build_failed_record(url, "non-html content") unless html?(content_type)

          build_success_record(
            url: url,
            final_url: final_url.to_s,
            pathname: final_url.path,
            html: response.read,
            content_type: content_type,
            redirected: redirected
          )
        ensure
          response&.close
        end
      rescue Async::TimeoutError
        build_failed_record(url, "timeout after #{config.timeout}s")
      rescue IOError, SocketError, Errno::ECONNREFUSED => e
        build_failed_record(url, e.message)
      end

      private

      attr_reader :client, :seed_host

      def config
        Nous.configuration
      end

      def html?(content_type)
        HTML_CONTENT_TYPES.any? { |type| content_type.include?(type) }
      end

      def build_success_record(url:, final_url:, pathname:, html:, content_type:, redirected:)
        FetchRecord.new(
          requested_url: url,
          final_url: final_url,
          pathname: pathname,
          html: html,
          content_type: content_type,
          ok: true,
          error: nil,
          redirected: redirected
        )
      end

      def build_failed_record(url, error)
        FetchRecord.new(
          requested_url: url,
          final_url: nil,
          pathname: Url.new(url).path,
          html: nil,
          content_type: nil,
          ok: false,
          error: error,
          redirected: false
        ).tap do |record|
          warn("[nous] skip #{url}: #{error}") if config.debug?
        end
      end
    end
  end
end
