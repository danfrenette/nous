# frozen_string_literal: true

module Nous
  module Extractor
    class ExtractionError < StandardError; end

    class Default < Command
      def initialize(selector: nil)
        @selector = selector
      end

      def extract(record)
        extracted = extract_content(record.html)
        markdown = convert_to_markdown(extracted[:content])

        success(payload: ExtractedContent.new(title: extracted[:title], content: markdown))
      rescue Client::ExtractionError, Converter::ConversionError => e
        failure(ExtractionError.new(e.message))
      end

      private

      attr_reader :selector

      def extract_content(html)
        result = Client.call(html:, selector:)
        raise result.error if result.failure?

        result.payload
      end

      def convert_to_markdown(html)
        result = Converter.call(html:)
        raise result.error if result.failure?

        result.payload
      end
    end
  end
end
