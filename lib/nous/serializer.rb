# frozen_string_literal: true

require "json"

module Nous
  class Serializer < Command
    class Error < Command::Error; end

    FORMATS = %i[text json].freeze

    def initialize(pages:, format: :text)
      @pages = pages
      @format = format.to_sym
      validate_format!
    end

    def call
      output = (format == :json) ? serialize_json : serialize_text
      success(payload: output)
    end

    private

    attr_reader :pages, :format

    def validate_format!
      raise Error, "unknown format: #{format}. Must be one of: #{FORMATS.join(", ")}" unless FORMATS.include?(format)
    end

    def serialize_text
      pages.map { |page| text_page(page) }.join("\n\n")
    end

    def serialize_json
      JSON.pretty_generate(pages.map { |page| json_page(page) })
    end

    def text_page(page)
      <<~XML
        <page>
          <title>#{page.title}</title>
          <url>#{page.url}</url>
          <content>
        #{page.content}
          </content>
        </page>
      XML
    end

    def json_page(page)
      {title: page.title, url: page.url, content: page.content}
    end
  end
end
