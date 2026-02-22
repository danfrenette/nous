# frozen_string_literal: true

module Nous
  class ExtractionRunner < Command
    class Error < Command::Error; end

    def initialize(raw_pages:, extractor:)
      @raw_pages = raw_pages
      @extractor = extractor
    end

    def call
      pages = raw_pages.each_slice(Nous.configuration.concurrency).each_with_object([]) do |batch, results|
        threads = batch.map { |raw| Thread.new { ExtractionThread.new(extractor:, raw_page: raw).call } }

        threads.each do |thread|
          result = thread.value
          results << result if result
        end
      end

      success(payload: pages)
    end

    private

    attr_reader :raw_pages, :extractor
  end
end
