# frozen_string_literal: true

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.setup

module Nous
  class << self
    attr_reader :configuration

    def configure(**options)
      @configuration = Configuration.new(**options)
    end

    def reset_configuration!
      @configuration = nil
    end

    def fetch(seed_url, extractor: Extractor::Default.new, **options)
      configure(**options)

      result = Fetcher.call(seed_url:, extractor:)
      raise result.error if result.failure?

      result.payload
    end

    def serialize(pages, format: :text)
      result = Serializer.call(pages:, format:)
      raise result.error if result.failure?

      result.payload
    end
  end
end
