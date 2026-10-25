# frozen_string_literal: true

module Nous
  module Extractor
    class Defuddle < Command
      def initialize(selector: nil)
        @selector = selector
      end

      def extract(record)
        result = Client.call(html: record.html, url: record.final_url, selector: @selector)
        return result if result.failure?

        success(payload: ExtractedContent.new(title: result.payload[:title], content: result.payload[:markdown]))
      end
    end
  end
end
