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
        extract_records
        report_extraction_outcomes
      end

      private

      attr_reader :records, :extractor, :pages, :failures

      def extract_records
        @pages = []
        @failures = []
        records.each_slice(Nous.configuration.concurrency) do |batch|
          threads = batch.map { |record| Thread.new { PageExtractor.call(extractor:, record:) } }
          batch.zip(threads).each do |record, thread|
            retain_outcome(record, thread.value)
          end
        end
      end

      def retain_outcome(record, result)
        if result.success?
          pages << result.payload
        else
          failures << {requested_url: record.requested_url, error: result.error}
        end
      end

      def report_extraction_outcomes
        success(payload: pages, metadata: {failures: failures})
      end
    end
  end
end
