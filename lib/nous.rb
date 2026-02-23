# frozen_string_literal: true

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.collapse("#{__dir__}/nous/primitives")
loader.setup

module Nous
  class << self
    attr_reader :configuration

    def configure(...)
      @configuration = ConfigurationBuilder.call(...)
    end

    def reset_configuration!
      @configuration = nil
    end

    def fetch(seed_url, extractor: Extractor::Default.new, http_client: nil, **options)
      configure(**options)

      result = Fetcher.call(seed_url:, extractor:, http_client:)
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
