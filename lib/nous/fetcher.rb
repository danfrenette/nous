# frozen_string_literal: true

module Nous
  class Fetcher < Command
    class FetchError < StandardError; end

    def initialize(seed_url:, extractor: Extractor::Default.new, http_client: nil)
      @seed_url = seed_url
      @extractor = extractor
      @http_client = http_client
      @single_page = Nous.configuration.single_page?
    end

    def call
      records = crawl
      successful, failed = records.partition(&:ok)

      if single_page && successful.empty?
        raise FetchError, failed.first&.error || "fetch failed"
      end

      pages = extract(successful)
      success(payload: pages)
    end

    private

    attr_reader :seed_url, :extractor, :http_client, :single_page

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
  end
end
