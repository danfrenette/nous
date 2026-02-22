# frozen_string_literal: true

require "addressable/uri"

module Nous
  class Url
    def initialize(raw)
      @uri = Addressable::URI.parse(raw.to_s.strip).normalize
      raise ArgumentError, "invalid URL: #{raw}" if uri.to_s.empty?
    rescue Addressable::URI::InvalidURIError => e
      raise ArgumentError, "invalid URL: #{e.message}"
    end

    def host
      uri.host
    end

    def path
      return "/" if uri.path.empty?

      uri.path
    end

    def http?
      %w[http https].include?(uri.scheme)
    end

    def to_s
      uri.to_s
    end

    def ==(other)
      other.is_a?(Url) && to_s == other.to_s
    end
    alias_method :eql?, :==

    def hash
      to_s.hash
    end

    private

    attr_reader :uri
  end
end
