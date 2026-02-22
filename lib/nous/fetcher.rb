# frozen_string_literal: true

module Nous
  class Fetcher < Command
    class FetchError < StandardError; end

    def initialize(seed_url:, extractor: Extractor::Default.new, http_client: nil)
      @seed_url = seed_url
      @extractor = extractor
      @http_client = http_client
    end

    def call
      raw_pages = crawl
      pages = extract(raw_pages)
      success(payload: pages)
    end

    private

    attr_reader :seed_url, :extractor, :http_client

    def crawl
      result = Crawler.call(seed_url:, http_client:)
      raise FetchError, result.error.message if result.failure?

      result.payload
    end

    def extract(raw_pages)
      result = ExtractionRunner.call(raw_pages:, extractor:)
      raise FetchError, result.error.message if result.failure?

      result.payload
    end
  end
end
