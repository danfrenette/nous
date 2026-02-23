# frozen_string_literal: true

module Nous
  class Crawler < Command
    class CrawlError < StandardError; end

    def initialize(seed_url:, http_client: nil)
      @seed_url = seed_url
      @http_client = http_client
      parse_seed!
    end

    def call
      if config.recursive?
        RecursivePageFetcher.call(seed_url:, http_client:)
      else
        SinglePageFetcher.call(url: seed_url, http_client:)
      end
    end

    private

    attr_reader :seed_url, :http_client

    def config
      Nous.configuration
    end

    def parse_seed!
      parsed = Url.new(seed_url)
      raise CrawlError, "seed URL must be http or https" unless parsed.http?
    rescue ArgumentError => e
      raise CrawlError, "invalid seed URL: #{e.message}"
    end
  end
end
