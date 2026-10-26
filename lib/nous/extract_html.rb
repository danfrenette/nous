# frozen_string_literal: true

require "nokogiri"

module Nous
  class ExtractHtml < Command
    class Error < StandardError; end
    class InvalidLimits < ArgumentError; end
    class InvalidContent < Error; end
    class NoContent < Error; end
    class UnsupportedContent < Error; end
    class InputLimitExceeded < Error; end
    class OutputLimitExceeded < Error; end

    class UnexpectedFailure < Error
      attr_reader :cause

      def initialize(cause)
        @cause = cause
        super("HTML extraction failed unexpectedly")
      end
    end

    def initialize(html:, source_url:, content_type: "text/html", format: :markdown,
      max_input_bytes: 25 * 1024 * 1024, max_output_bytes: 32 * 1024 * 1024)
      @html = html
      @source_url = source_url
      @content_type = content_type
      @format = format
      @max_input_bytes = max_input_bytes
      @max_output_bytes = max_output_bytes
    end

    def call
      verify_extraction_request
      decode_retained_html
      extract_readable_content
      render_content
      verify_extracted_content
      report_extraction
    rescue Error, InvalidLimits => error
      failure(error)
    rescue => error
      failure(UnexpectedFailure.new(error))
    end

    private

    attr_reader :html, :source_url, :content_type, :format, :max_input_bytes, :max_output_bytes

    def verify_extraction_request
      unless [max_input_bytes, max_output_bytes].all? { |limit| limit.is_a?(Integer) && limit.positive? }
        raise InvalidLimits, "Byte limits must be positive integers"
      end
      raise InvalidContent, "HTML must be a byte string" unless html.is_a?(String)
      raise InputLimitExceeded, "HTML exceeds input byte limit" if html.bytesize > max_input_bytes
      raise UnsupportedContent, "Unsupported output format" unless [:markdown, :text].include?(format)
      unless content_type.is_a?(String) && ["text/html", "application/xhtml+xml"].include?(content_type.split(";", 2).first.to_s.strip.downcase)
        raise UnsupportedContent, "Unsupported HTML content type"
      end
    end

    def decode_retained_html
      result = DecodeHtml.new(html: html, content_type: content_type).call
      raise result.error if result.failure?

      @decoded = result.payload
      @encoding = result.metadata.fetch(:encoding)
    rescue DecodeHtml::InvalidContent => error
      raise InvalidContent, error.message
    rescue DecodeHtml::UnsupportedContent => error
      raise UnsupportedContent, error.message
    end

    def extract_readable_content
      result = Extractor::Defuddle::Client.new(html: @decoded, url: source_url).call
      raise result.error if result.failure?

      @readable = result.payload
      @title = @readable[:title]
    rescue Extractor::Defuddle::Client::NoContent => error
      raise NoContent.new("HTML has no readable content"), cause: error
    end

    def render_content
      @content = (format == :text) ? render_plain_text : @readable[:markdown]
    end

    def render_plain_text
      Nokogiri::HTML.fragment(@readable[:content]).tap do |fragment|
        fragment.css("p, div, h1, h2, h3, h4, h5, h6, li, tr, br").each do |node|
          node.add_next_sibling(Nokogiri::XML::Text.new(" ", fragment.document))
        end
      end.text.gsub(/\s+/, " ").strip
    end

    def verify_extracted_content
      raise NoContent, "HTML has no readable content" if @content.strip.empty?
      if @content.bytesize + @title.bytesize > max_output_bytes
        raise OutputLimitExceeded, "Extracted content exceeds output byte limit"
      end
    end

    def report_extraction
      success(payload: ExtractedContent.new(title: @title, content: @content),
        metadata: {source_url: source_url, content_type: content_type, encoding: @encoding, format: format, limitations: ["static_html_only", "authentication_not_detected"]})
    end
  end
end
