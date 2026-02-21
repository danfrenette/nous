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
      pages = crawl.filter_map { |raw| process_page(raw) }
      success(payload: pages)
    end

    private

    attr_reader :seed_url, :extractor, :crawler_options

    def crawl
      result = Crawler.call(seed_url:, **crawler_options)
      raise Error, result.error.message if result.failure?

      result.payload
    end

    def process_page(raw)
      extracted = extractor.extract(raw)

      Page.new(
        title: extracted[:title],
        url: raw[:url],
        pathname: raw[:pathname],
        content: extracted[:content]
      )
    rescue Nous::Error
      nil
    end
  end
end
