# frozen_string_literal: true

require "readability"

module Nous
  module Extractor
    class Default
      class Client < Command
        class ExtractionError < StandardError; end

        NOISY_TAGS = %w[script style nav footer].freeze

        def initialize(html:, selector: nil)
          @html = html
          @selector = selector
        end

        def call
          readable = ::Readability::Document.new(prepared_html)

          text = Nokogiri::HTML(readable.content).text.strip
          return failure(ExtractionError.new("readability returned no content")) if text.empty?

          title = resolve_title(readable)
          success(payload: {title: title, content: readable.content})
        end

        private

        attr_reader :html, :selector

        def prepared_html
          doc = Nokogiri::HTML(html)
          original_title(doc)
          doc = scope(doc, selector) if selector
          strip_tags(doc)
          doc.to_html
        end

        def original_title(doc)
          @original_title ||= doc.at_css("title")&.text.to_s.strip
        end

        def scope(doc, selector)
          scoped = doc.at_css(selector)
          return doc unless scoped

          Nokogiri::HTML.fragment(scoped.to_html)
        end

        def strip_tags(doc)
          NOISY_TAGS.each { |tag| doc.css(tag).each(&:remove) }
        end

        def resolve_title(readable)
          title = readable.title.to_s.strip
          title = @original_title if title.empty?
          title = title_from_content(readable.content) if title.empty?
          title
        end

        def title_from_content(content)
          Nokogiri::HTML(content).at_css("h1")&.text.to_s.strip
        end
      end
    end
  end
end
