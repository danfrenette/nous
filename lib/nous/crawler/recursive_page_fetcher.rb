# frozen_string_literal: true

require "async"
require "async/http/internet"

module Nous
  class Crawler < Command
    class RecursivePageFetcher < Command
      def initialize(seed_url:, http_client: nil)
        @seed_uri = Url.new(seed_url)
        @http_client = http_client
        @records = []
        @queue = [url_filter.canonicalize(seed_uri)]
        @seen = Set.new(queue)
      end

      def call
        prepare_crawl_logging
        acquire_linked_records
        report_acquired_records
      end

      private

      attr_reader :seed_uri, :http_client, :records, :queue, :seen

      def prepare_crawl_logging
        suppress_async_warnings unless config.debug?
      end

      def acquire_linked_records
        open_connection { |client| crawl(client) }
      end

      def report_acquired_records
        success(payload: records)
      end

      def config
        Nous.configuration
      end

      def crawl(client)
        fetch_and_enqueue(queue.shift(config.concurrency), client) while queue.any? && within_limit?
      end

      def fetch_and_enqueue(batch, client)
        fetch_batch(batch, client).each do |record|
          break unless within_limit?

          records << record
          next unless record.ok
          seen << record.final_url
          enqueue_links(record)
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

      def enqueue_links(record)
        link_extractor.extract(record.final_url, record.html).each do |url|
          next if seen.include?(url)

          seen << url
          queue << url
        end
      end

      def within_limit?
        records.count(&:ok) < config.limit
      end

      def open_connection
        client = http_client || Async::HTTP::Internet.new

        Async do
          yield client
        ensure
          client.close
        end.wait
      end

      def page_fetcher(client)
        AsyncPageFetcher.new(client:, seed_host: seed_uri.host)
      end

      def url_filter
        @url_filter ||= UrlFilter.new(seed_uri:)
      end

      def link_extractor
        @link_filter ||= LinkExtractor.new(url_filter:)
      end

      def suppress_async_warnings
        require "console"
        Console.logger.level = :error
      end
    end
  end
end
