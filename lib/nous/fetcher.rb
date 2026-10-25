# frozen_string_literal: true

module Nous
  class Fetcher < Command
    class FetchError < StandardError; end

    def initialize(seed_url:, extractor: Extractor::Default.new, http_client: nil, details: false)
      @seed_url = seed_url
      @extractor = extractor
      @http_client = http_client
      @single_page = Nous.configuration.single_page?
      @details = details
    end

    def call
      acquire_records
      verify_acquisition
      extract_readable_pages
      report_fetch_outcomes
    end

    private

    attr_reader :seed_url, :extractor, :http_client, :single_page, :details

    def acquire_records
      @records = crawl
      @successful_records, @failed_records = @records.partition(&:ok)
    end

    def verify_acquisition
      if single_page && !details && @successful_records.empty?
        raise FetchError, @failed_records.first&.error || "fetch failed"
      end
    end

    def extract_readable_pages
      @extraction = ExtractionRunner.call(records: @successful_records, extractor:)
      raise @extraction.error if @extraction.failure?
    end

    def report_fetch_outcomes
      return success(payload: @extraction.payload) unless details

      success(payload: FetchResult.new(
        pages: @extraction.payload,
        failures: build_failures(@failed_records) + @extraction.metadata.fetch(:failures),
        total_requested: @records.length
      ))
    end

    def crawl
      result = Crawler.call(seed_url:, http_client:)
      raise FetchError, result.error.message if result.failure?

      result.payload
    end

    def build_failures(records)
      records.map do |record|
        {
          requested_url: record.requested_url,
          error: record.error
        }
      end
    end
  end
end
