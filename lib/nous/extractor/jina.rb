# frozen_string_literal: true

module Nous
  module Extractor
    class Jina < Command
      def initialize(api_key: nil, timeout: 30, **client_options)
        @client = Client.new(api_key: api_key || ENV["JINA_API_KEY"], timeout:, **client_options)
      end

      def extract(record)
        body = client.get(record.final_url)

        success(payload: ExtractedContent.new(
          title: body.dig("data", "title") || "",
          content: body.dig("data", "content") || ""
        ))
      rescue Client::RequestError => e
        failure(ExtractionError.new(e.message))
      end

      private

      attr_reader :client
    end
  end
end
