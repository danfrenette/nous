# frozen_string_literal: true

require "async"
require "async/http/internet"
require "nokogiri"
require "uri"

module Nous
  class Crawler < Command
    class CrawlError < StandardError; end

    def initialize(seed_url:, http_client: nil)
      @seed_uri = parse_seed!(seed_url)
      @http_client = http_client
    end

    def call
      suppress_async_warnings unless config.debug?

      pages = []
      queue = [url_filter.canonicalize(seed_uri)]
      seen = Set.new(queue)

      Async do
        client = http_client || Async::HTTP::Internet.new
        begin
          crawl(queue:, seen:, pages:, client:)
        ensure
          client.close
        end
      end.wait

      success(payload: pages)
    end

    private

    attr_reader :seed_uri, :http_client

    def config
      Nous.configuration
    end

    def crawl(queue:, seen:, pages:, client:)
      while queue.any? && pages.length < config.limit
        batch = queue.shift(config.concurrency)
        fetch_batch(batch, client).each do |page|
          next unless page

          seen << page.url
          pages << page
          break if pages.length >= config.limit

          link_extractor.extract(page.url, page.html).each do |url|
            next if seen.include?(url)

            seen << url
            queue << url
          end
        end
      end
    end

    def fetch_batch(urls, client)
      tasks = []

      Async do |task|
        urls.each do |url|
          tasks << task.async { page_fetcher(client).fetch(url) }
        end
      end.wait

      tasks.map(&:wait)
    end

    def url_filter
      @url_filter ||= UrlFilter.new(seed_uri:)
    end

    def link_extractor
      @link_extractor ||= LinkExtractor.new(url_filter:)
    end

    def page_fetcher(client)
      PageFetcher.new(client:, seed_host: seed_uri.host)
    end

    def suppress_async_warnings
      require "console"
      Console.logger.level = :error
    end

    def parse_seed!(url)
      parsed = Url.new(url)
      raise CrawlError, "seed URL must be http or https" unless parsed.http?

      parsed
    rescue ArgumentError => e
      raise CrawlError, "invalid seed URL: #{e.message}"
    end
  end
end
