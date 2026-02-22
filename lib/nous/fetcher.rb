# frozen_string_literal: true

module Nous
  class Fetcher < Command
    class Error < Command::Error; end

    def initialize(seed_url:, extractor: Extractor::Default.new)
      @seed_url = seed_url
      @extractor = extractor
    end

    def call
      raw_pages = crawl
      pages = extract(raw_pages)
      success(payload: pages)
    end

    private

    attr_reader :seed_url, :extractor

    def crawl
      result = Crawler.call(seed_url:)
      raise Error, result.error.message if result.failure?

      result.payload
    end

    def extract(raw_pages)
      result = ExtractionRunner.call(raw_pages:, extractor:)
      raise Error, result.error.message if result.failure?

      result.payload
    end
  end
end
