# frozen_string_literal: true

module Nous
  class Crawler < Command
    class UrlFilter
      IGNORED_SCHEMES = %w[mailto: javascript: tel:].freeze

      def initialize(seed_uri:)
        @host = seed_uri.host
        @match = Nous.configuration.match
        @keep_query = Nous.configuration.keep_query
      end

      def canonicalize(uri)
        uri = URI.parse(uri.to_s)
        uri.fragment = nil
        uri.query = nil unless keep_query
        uri.path = "/" if uri.path.empty?
        uri.to_s
      end

      def allowed?(href)
        return false if href.strip.empty?

        IGNORED_SCHEMES.none? { |s| href.start_with?(s) }
      end

      def same_host?(url)
        url.http? && url.host == host
      end

      def matches_path?(path)
        return true if match.empty?

        match.any? { |pattern| File.fnmatch(pattern, path, File::FNM_PATHNAME | File::FNM_EXTGLOB) }
      end

      private

      attr_reader :host, :match, :keep_query
    end
  end
end
