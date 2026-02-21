# frozen_string_literal: true

module Nous
  class Fetcher < Command
    class Error < Command::Error; end

    def initialize(seed_url:, extractor: Extractor::Default.new, **crawler_options)
      @seed_url = seed_url
      @extractor = extractor
      @crawler_options = crawler_options
    end

    def call
      raw_pages = crawl
      pages = extract(raw_pages)
      success(payload: pages)
    end

    private

    attr_reader :seed_url, :extractor, :crawler_options

    def crawl
      result = Crawler.call(seed_url:, **crawler_options)
      raise Error, result.error.message if result.failure?

      result.payload
    end

    def extract(raw_pages)
      ExtractionRunner.new(
        raw_pages:,
        extractor:,
        concurrency: crawler_options.fetch(:concurrency, 3),
        verbose: crawler_options.fetch(:verbose, false)
      ).call
    end
  end
end
