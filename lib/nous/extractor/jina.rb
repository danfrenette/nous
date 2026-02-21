# frozen_string_literal: true

module Nous
  class Extractor
    class Jina
      class Error < Nous::Error; end

      def initialize(api_key: nil, timeout: 30, **client_options)
        @client = Client.new(api_key: api_key || ENV["JINA_API_KEY"], timeout:, **client_options)
      end

      def extract(page)
        body = client.get(page[:url])

        {title: body.dig("data", "title") || "", content: body.dig("data", "content") || ""}
      rescue Client::Error => e
        raise Error, e.message
      end

      private

      attr_reader :client
    end
  end
end
