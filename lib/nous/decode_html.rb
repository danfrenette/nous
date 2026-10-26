# frozen_string_literal: true

require "nokogiri"

module Nous
  # Owns charset precedence and byte validation for both HTML entry points.
  class DecodeHtml < Command
    class Error < StandardError; end
    class InvalidContent < Error; end
    class UnsupportedContent < Error; end

    def initialize(html:, content_type:)
      @html = html
      @content_type = content_type
    end

    def call
      decode_bytes
      report_decoding
    rescue Error => error
      failure(error)
    end

    private

    attr_reader :html, :content_type

    def select_encoding(name)
      Encoding.find(name)
    rescue ArgumentError
      raise UnsupportedContent, "Unsupported HTML charset"
    end

    def decode_bytes
      raise InvalidContent, "HTML must be a byte string" unless html.is_a?(String)
      bytes = html.b
      declared = charset_parameter(content_type.to_s)
      @encoding = select_encoding(declared || bom_encoding(bytes) || meta_encoding(bytes) || "UTF-8")
      encoded = bytes.dup.force_encoding(@encoding)
      raise InvalidContent, "HTML contains invalid encoded bytes" unless encoded.valid_encoding?

      @decoded = encoded.encode(Encoding::UTF_8)
      @decoded = @decoded.delete_prefix("\uFEFF")
      raise InvalidContent, "HTML contains NUL characters" if @decoded.include?("\0")
    rescue EncodingError
      raise InvalidContent, "HTML cannot be decoded as UTF-8"
    end

    def bom_encoding(bytes)
      return "UTF-8" if bytes.start_with?("\xEF\xBB\xBF".b)
      return "UTF-32BE" if bytes.start_with?("\x00\x00\xFE\xFF".b)
      return "UTF-32LE" if bytes.start_with?("\xFF\xFE\x00\x00".b)
      return "UTF-16BE" if bytes.start_with?("\xFE\xFF".b)
      "UTF-16LE" if bytes.start_with?("\xFF\xFE".b)
    end

    def charset_parameter(value)
      value.scan(/(?:\A|;)\s*([^;=\s]+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^;\s]*))/).each do |name, quoted, single_quoted, bare|
        return quoted || single_quoted || bare if name.casecmp?("charset")
      end
      nil
    end

    def meta_encoding(bytes)
      document = Nokogiri::HTML(bytes.byteslice(0, 1024), nil, "ISO-8859-1")
      document.css("meta").each do |meta|
        return meta["charset"] if meta["charset"]
        if meta["http-equiv"].to_s.casecmp?("content-type")
          declared = charset_parameter(meta["content"].to_s)
          return declared if declared
        end
      end
      nil
    end

    def report_decoding
      success(payload: @decoded, metadata: {encoding: @encoding.name})
    end
  end
end
