# frozen_string_literal: true

require "addressable/uri"

module Nous
  class UrlResolver < Command
    class ResolutionError < StandardError; end

    def initialize(base_url:, href:)
      @base_uri = Addressable::URI.parse(base_url.to_s)
      @href = href.to_s.strip
    end

    def call
      joined = base_uri.join(href)
      success(payload: Url.new(joined))
    rescue Addressable::URI::InvalidURIError => e
      failure(ResolutionError.new("cannot resolve #{href.inspect}: #{e.message}"))
    end

    private

    attr_reader :base_uri, :href
  end
end
