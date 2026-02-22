# frozen_string_literal: true

module Nous
  class Crawler < Command
    class LinkExtractor
      def initialize(url_filter:)
        @url_filter = url_filter
      end

      def extract(current_url, html)
        anchors(html).filter_map { |href| resolve(current_url, href) }.uniq
      end

      private

      attr_reader :url_filter

      def anchors(html)
        Nokogiri::HTML(html).css("a[href]").map { |node| node["href"] }
      end

      def resolve(current_url, href)
        return unless url_filter.allowed?(href)

        result = UrlResolver.call(base_url: current_url, href:)
        return unless result.success?

        url = result.payload
        return unless url_filter.same_host?(url)

        canonical = url_filter.canonicalize(url)
        return unless url_filter.matches_path?(Url.new(canonical).path)

        canonical
      end
    end
  end
end
