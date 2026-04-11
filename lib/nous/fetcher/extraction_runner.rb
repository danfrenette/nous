# frozen_string_literal: true

module Nous
  class Fetcher < Command
    class ExtractionRunner < Command
      class ExtractionError < StandardError; end

      def initialize(records:, extractor:)
        @records = records
        @extractor = extractor
      end

      def call
        pages = records.each_slice(Nous.configuration.concurrency).each_with_object([]) do |batch, results|
          threads = batch.map { |record| Thread.new { PageExtractor.call(extractor:, record:) } }

          threads.each do |thread|
            result = thread.value
            results << result.payload if result.success?
          end
        end

        success(payload: pages)
      end

      private

      attr_reader :records, :extractor
    end
  end
end
