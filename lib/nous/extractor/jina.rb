# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Nous
  class Extractor
    class Jina
      class Error < Nous::Error; end

      BASE_URL = "https://r.jina.ai"

      def initialize(api_key: nil, timeout: 30)
        @api_key = api_key || ENV["JINA_API_KEY"]
        @timeout = timeout
      end

      def extract(page)
        response = fetch(page[:url])
        body = parse_response(response)

        {title: body.dig("data", "title") || "", content: body.dig("data", "content") || ""}
      end

      private

      attr_reader :api_key, :timeout

      def fetch(url)
        uri = URI("#{BASE_URL}/#{url}")
        request = Net::HTTP::Get.new(uri)
        request["Accept"] = "application/json"
        request["X-No-Cache"] = "true"
        request["Authorization"] = "Bearer #{api_key}" if api_key

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = timeout
        http.read_timeout = timeout

        http.request(request)
      end

      def parse_response(response)
        raise Error, "Jina API returned #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)
      rescue JSON::ParserError => e
        raise Error, "Jina API returned invalid JSON: #{e.message}"
      end
    end
  end
end
