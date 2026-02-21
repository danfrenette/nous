# frozen_string_literal: true

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.setup

module Nous
  module_function

  def fetch(seed_url, **options)
    result = Fetcher.call(seed_url:, **options)
    raise result.error if result.failure?

    result.payload
  end

  def serialize(pages, format: :text)
    result = Serializer.call(pages:, format:)
    raise result.error if result.failure?

    result.payload
  end
end
