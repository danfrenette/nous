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
      records = crawl
      successful_records, failed_records = records.partition(&:ok)

      if single_page && !details && successful_records.empty?
        raise FetchError, failed_records.first&.error || "fetch failed"
      end

      pages = extract(successful_records)

      if details
        success(payload: FetchResult.new(
          pages: pages,
          failures: build_failures(failed_records),
          total_requested: records.length
        ))
      else
        success(payload: pages)
      end
    end

    private

    attr_reader :seed_url, :extractor, :http_client, :single_page, :details

    def crawl
      result = Crawler.call(seed_url:, http_client:)
      raise FetchError, result.error.message if result.failure?

      result.payload
    end

    def extract(records)
      result = ExtractionRunner.call(records:, extractor:)
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
