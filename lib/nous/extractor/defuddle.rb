# frozen_string_literal: true

module Nous
  module Extractor
    class Defuddle < Command
      def initialize(selector: nil)
        @selector = selector
      end

      def extract(record)
        decoded = DecodeHtml.call(html: record.html, content_type: record.content_type)
        raise decoded.error if decoded.failure?

        result = Client.call(html: decoded.payload, url: record.final_url, selector: @selector)
        return result if result.failure?

        success(payload: ExtractedContent.new(title: result.payload[:title], content: result.payload[:markdown]))
      rescue DecodeHtml::Error => error
        failure(ExtractionError.new(error.message))
      end
    end
  end
end
