# frozen_string_literal: true

module Nous
  class Fetcher < Command
    class PageExtractor < Command
      def initialize(extractor:, raw_page:)
        @extractor = extractor
        @raw_page = raw_page
      end

      def call
        result = extractor.extract(raw_page)

        unless result.success?
          warn("[nous] extract skip #{raw_page.url}: #{result.error.message}") if Nous.configuration.debug?
          return failure(result.error)
        end

        page = Page.new(
          title: result.payload.title,
          url: raw_page.url,
          pathname: raw_page.pathname,
          content: result.payload.content
        )

        success(payload: page)
      end

      private

      attr_reader :extractor, :raw_page
    end
  end
end
