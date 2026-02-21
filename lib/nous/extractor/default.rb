# frozen_string_literal: true

module Nous
  class Extractor
    class Default
      def initialize(selector: nil)
        @selector = selector
      end

      def extract(page)
        extracted = extract_content(page[:html])
        markdown = convert_to_markdown(extracted[:content])

        {title: extracted[:title], content: markdown}
      end

      private

      attr_reader :selector

      def extract_content(html)
        result = Extractor.call(html:, selector:)
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
