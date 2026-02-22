# frozen_string_literal: true

module Nous
  class Fetcher < Command
    class ExtractionThread
      def initialize(extractor:, raw_page:)
        @extractor = extractor
        @raw_page = raw_page
      end

      def call
        extracted = extractor.extract(raw_page)

        Page.new(
          title: extracted[:title],
          url: raw_page[:url],
          pathname: raw_page[:pathname],
          content: extracted[:content]
        )
      rescue Extractor::ExtractionError => e
        warn("[nous] extract skip #{raw_page[:url]}: #{e.message}") if Nous.configuration.debug?
        nil
      end

      private

      attr_reader :extractor, :raw_page
    end
  end
end
