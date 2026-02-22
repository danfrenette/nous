# frozen_string_literal: true

require "readability"

module Nous
  module Extractor
    class Default
      class Client < Command
        class ExtractionError < StandardError; end

        NOISY_TAGS = %w[script style link nav header footer img video svg].freeze

        def initialize(html:, selector: nil)
          @html = html
          @selector = selector
        end

        def call
          doc = Nokogiri::HTML(html)
          doc = scope_to_selector(doc) if selector
          strip_noisy_tags(doc)

          readable = ::Readability::Document.new(doc.to_html)
          text = Nokogiri::HTML(readable.content).text.strip

          return failure(ExtractionError.new("readability returned no content")) if text.empty?

          success(payload: {title: readable.title, content: readable.content})
        end

        private

        attr_reader :html, :selector

        def scope_to_selector(doc)
          scoped = doc.at_css(selector)
          return doc unless scoped

          fragment = Nokogiri::HTML::Document.new
          fragment.root = scoped
          fragment
        end

        def strip_noisy_tags(doc)
          NOISY_TAGS.each { |tag| doc.css(tag).each(&:remove) }
        end
      end
    end
  end
end
