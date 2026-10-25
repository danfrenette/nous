# frozen_string_literal: true

module Nous
  class Fetcher < Command
    class PageExtractor < Command
      def initialize(extractor:, record:)
        @extractor = extractor
        @record = record
      end

      def call
        extract_content
        report_page
      rescue => error
        failure(error)
      end

      private

      attr_reader :extractor, :record

      def extract_content
        @extraction = extractor.extract(record)
      end

      def report_page
        result = @extraction
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
    end
  end
end
