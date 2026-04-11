# frozen_string_literal: true

module Nous
  class Fetcher < Command
    class PageExtractor < Command
      def initialize(extractor:, record:)
        @extractor = extractor
        @record = record
      end

      def call
        result = extractor.extract(record)

        unless result.success?
          warn("[nous] extract skip #{record.final_url}: #{result.error.message}") if Nous.configuration.debug?
          return failure(result.error)
        end

        page = Page.new(
          title: result.payload.title,
          url: record.final_url,
          pathname: record.pathname,
          content: result.payload.content,
          metadata: {
            extractor: extractor.class.name,
            requested_url: record.requested_url,
            content_type: record.content_type,
            redirected: record.redirected
          }
        )

        success(payload: page)
      end

      private

      attr_reader :extractor, :record
    end
  end
end
