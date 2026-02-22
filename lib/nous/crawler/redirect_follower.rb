# frozen_string_literal: true

module Nous
  class Crawler < Command
    class RedirectFollower < Command
      class RedirectError < StandardError; end

      MAX_HOPS = 5

      def initialize(client:, seed_host:, url:, hops_remaining: MAX_HOPS)
        @client = client
        @seed_host = seed_host
        @url = url
        @hops_remaining = hops_remaining
      end

      def call
        response = client.get(url, {})

        return success(payload: [response, Url.new(url)]) unless redirect?(response.status)

        response.close
        follow(response.headers["location"])
      end

      private

      attr_reader :client, :seed_host, :url, :hops_remaining

      def redirect?(status)
        (300..399).cover?(status)
      end

      def follow(location)
        target = resolve_target(location)
        return target if target.failure?

        self.class.call(client:, seed_host:, url: target.payload.to_s, hops_remaining: hops_remaining - 1)
      end

      def resolve_target(location)
        return failure(RedirectError.new("redirect without location from #{url}")) unless location
        return failure(RedirectError.new("too many redirects from #{url}")) if hops_remaining <= 0

        result = UrlResolver.call(base_url: url, href: location)
        return failure(RedirectError.new(result.error.message)) if result.failure?

        unless safe?(result.payload)
          return failure(RedirectError.new("redirect to #{result.payload} outside #{seed_host}"))
        end

        result
      end

      def safe?(target)
        target.http? && target.host == seed_host
      end
    end
  end
end
