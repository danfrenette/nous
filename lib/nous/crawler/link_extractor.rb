# frozen_string_literal: true

module Nous
  class Crawler < Command
    class LinkExtractor
      def initialize(url_filter:, verbose: false)
        @url_filter = url_filter
        @verbose = verbose
      end

      def extract(current_url, html)
        base_uri = URI.parse(current_url)

        anchors(html).filter_map { |href| resolve(base_uri, href) }.uniq
      end

      private

      attr_reader :url_filter, :verbose

      def anchors(html)
        Nokogiri::HTML(html).css("a[href]").map { |node| node["href"] }
      end

      def resolve(base_uri, href)
        return unless url_filter.allowed?(href)

        uri = URI.join(base_uri, href)
        return unless url_filter.same_host?(uri)

        canonical = url_filter.canonicalize(uri)
        return unless url_filter.matches_path?(URI.parse(canonical).path)

        canonical
      rescue URI::InvalidURIError => e
        warn("[nous] malformed href #{href.inspect}: #{e.message}") if verbose
        nil
      end
    end
  end
end
