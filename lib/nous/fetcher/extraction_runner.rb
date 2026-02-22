# frozen_string_literal: true

module Nous
  class Fetcher < Command
    class ExtractionRunner < Command
      class ExtractionError < StandardError; end

      def initialize(raw_pages:, extractor:)
        @raw_pages = raw_pages
        @extractor = extractor
      end

      def call
        pages = raw_pages.each_slice(Nous.configuration.concurrency).each_with_object([]) do |batch, results|
          threads = batch.map { |raw_page| Thread.new { PageExtractor.call(extractor:, raw_page:) } }

          threads.each do |thread|
            result = thread.value
            results << result.payload if result.success?
          end
        end

        success(payload: pages)
      end

      private

      attr_reader :raw_pages, :extractor
    end
  end
end
