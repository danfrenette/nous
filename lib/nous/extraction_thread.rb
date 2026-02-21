# frozen_string_literal: true

module Nous
  class ExtractionThread
    def initialize(extractor:, raw_page:, verbose: false)
      @extractor = extractor
      @raw_page = raw_page
      @verbose = verbose
    end

    def call
      extracted = extractor.extract(raw_page)

      Page.new(
        title: extracted[:title],
        url: raw_page[:url],
        pathname: raw_page[:pathname],
        content: extracted[:content]
      )
    rescue Nous::Error => e
      warn("[nous] extract skip #{raw_page[:url]}: #{e.message}") if verbose
      nil
    end

    private

    attr_reader :extractor, :raw_page, :verbose
  end
end
