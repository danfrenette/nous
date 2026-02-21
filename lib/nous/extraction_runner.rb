# frozen_string_literal: true

module Nous
  class ExtractionRunner
    def initialize(raw_pages:, extractor:, concurrency: 3, verbose: false)
      @raw_pages = raw_pages
      @extractor = extractor
      @concurrency = Integer(concurrency).clamp(1, 20)
      @verbose = verbose
    end

    def call
      raw_pages.each_slice(concurrency).each_with_object([]) do |batch, pages|
        threads = batch.map { |raw| Thread.new { build_thread(raw).call } }

        threads.each do |thread|
          result = thread.value
          pages << result if result
        end
      end
    end

    private

    attr_reader :raw_pages, :extractor, :concurrency, :verbose

    def build_thread(raw_page)
      ExtractionThread.new(extractor:, raw_page:, verbose:)
    end
  end
end
