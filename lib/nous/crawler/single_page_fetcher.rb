# frozen_string_literal: true

require "faraday"
require "faraday/follow_redirects"

module Nous
  class Crawler < Command
    class SinglePageFetcher < Command
      class FetchError < StandardError; end

      HTML_CONTENT_TYPES = %w[text/html application/xhtml+xml].freeze
      MAX_REDIRECTS = 5

      def initialize(url:, http_client: nil)
        @url = url
        @seed_host = Url.new(url).host
        @connection = http_client || build_connection
      end

      def call
        response = connection.get(url)
        final_url = resolve_final_url(response)

        validate_host!(final_url)
        validate_html!(response)

        raw_page = RawPage.new(url: final_url.to_s, pathname: final_url.path, html: response.body)
        success(payload: [raw_page])
      rescue FetchError => e
        failure(e)
      rescue Faraday::Error => e
        failure(FetchError.new(e.message))
      end

      private

      attr_reader :url, :seed_host, :connection

      def config
        Nous.configuration
      end

      def resolve_final_url(response)
        location = response.env.url.to_s
        Url.new(location)
      end

      def validate_host!(final_url)
        return if final_url.host == seed_host

        raise FetchError, "redirected to #{final_url} outside #{seed_host}"
      end

      def validate_html!(response)
        content_type = response.headers["content-type"].to_s
        return if HTML_CONTENT_TYPES.any? { |type| content_type.include?(type) }

        raise FetchError, "non-html content: #{content_type}"
      end

      def build_connection
        Faraday.new do |f|
          f.response :follow_redirects, limit: MAX_REDIRECTS
          f.response :raise_error

          f.options.timeout = config.timeout
          f.options.open_timeout = config.timeout
        end
      end
    end
  end
end
