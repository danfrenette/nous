# frozen_string_literal: true

module Nous
  class Fetcher < Command
    class Error < Command::Error; end

    def initialize(seed_url:, selector: nil, **crawler_options)
      @seed_url = seed_url
      @selector = selector
      @crawler_options = crawler_options
    end

    def call
      pages = crawl.filter_map { |raw| process_page(raw) }
      success(payload: pages)
    end

    private

    attr_reader :seed_url, :selector, :crawler_options

    def crawl
      result = Crawler.call(seed_url:, **crawler_options)
      raise Error, result.error.message if result.failure?

      result.payload
    end

    def extract(html)
      result = Extractor.call(html:, selector:)
      raise Error, result.error.message if result.failure?

      result.payload
    end

    def convert(html)
      result = Converter.call(html:)
      raise Error, result.error.message if result.failure?

      result.payload
    end

    def process_page(raw)
      extracted = extract(raw[:html])
      markdown = convert(extracted[:content])

      Page.new(
        title: extracted[:title],
        url: raw[:url],
        pathname: raw[:pathname],
        content: markdown
      )
    rescue Error
      nil
    end
  end
end
