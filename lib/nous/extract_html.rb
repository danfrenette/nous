# frozen_string_literal: true

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

    def select_encoding(name)
      Encoding.find(name)
    rescue ArgumentError
      raise UnsupportedContent, "Unsupported HTML charset"
    end

    def decode_retained_html
      bytes = html.b
      declared = charset_parameter(content_type)
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

    def extract_readable_content
      result = Extractor::Default::Client.new(html: @decoded).call
      if result.failure?
        if result.error.is_a?(Extractor::Default::Client::ExtractionError)
          raise NoContent.new("HTML has no readable content"), cause: result.error
        end
        raise result.error
      end

      @readable = result.payload
      @title = @readable[:title].encode(Encoding::UTF_8)
    end

    def render_content
      if format == :text
        fragment = Nokogiri::HTML.fragment(@readable[:content])
        fragment.css("p, div, h1, h2, h3, h4, h5, h6, li, tr, br").each do |node|
          node.add_next_sibling(Nokogiri::XML::Text.new(" ", fragment.document))
        end
        @content = fragment.text.gsub(/\s+/, " ").strip
        return
      end

      result = Converter.new(html: @readable[:content]).call
      raise result.error if result.failure?

      @content = result.payload
    end

    def verify_extracted_content
      unless @content.encoding == Encoding::UTF_8 && @content.valid_encoding? && !@content.include?("\0")
        raise InvalidContent, "Extracted content is not valid UTF-8"
      end
      raise NoContent, "HTML has no readable content" if @content.strip.empty?
      title = @title
      unless title.encoding == Encoding::UTF_8 && title.valid_encoding? && !title.include?("\0")
        raise InvalidContent, "Extracted title is not valid UTF-8"
      end
      if @content.bytesize + title.bytesize > max_output_bytes
        raise OutputLimitExceeded, "Extracted content exceeds output byte limit"
      end
    end

    def report_extraction
      success(payload: ExtractedContent.new(title: @title, content: @content),
        metadata: {source_url: source_url, content_type: content_type, encoding: @encoding.name, format: format, limitations: ["static_html_only", "authentication_not_detected"]})
    end
  end
end
