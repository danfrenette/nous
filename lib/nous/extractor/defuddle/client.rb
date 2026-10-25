# frozen_string_literal: true

require "json"

module Nous
  module Extractor
    class Defuddle
      class Client < Command
        class NoContent < ExtractionError; end
        ProcessError = RunProcess::Error

        def initialize(html:, url:, selector: nil)
          @html = html
          @url = url
          @selector = selector
        end

        def call
          verify_input
          run_defuddle
          validate_response
          report_content
        rescue NoContent, ProcessError => error
          failure(error)
        rescue JSON::JSONError, EncodingError
          failure(ProcessError.new("Invalid Defuddle process response"))
        end

        private

        def verify_input
          unless @html.is_a?(String)
            raise ProcessError, "Defuddle HTML input must be a string"
          end
        end

        def run_defuddle
          request = JSON.generate(html: @html, url: @url, selector: @selector)
          result = RunProcess.call(request: request)
          raise result.error if result.failure?

          @response = JSON.parse(result.payload, symbolize_names: true)
        end

        def validate_response
          unless @response.is_a?(Hash) && [:title, :content, :markdown].all? { |key| valid_text?(@response[key]) }
            raise ProcessError, "Invalid Defuddle response fields"
          end
          if @response[:markdown].strip.empty?
            raise NoContent, "HTML has no readable content"
          end
        end

        def valid_text?(value)
          value.is_a?(String) && value.encoding == Encoding::UTF_8 && value.valid_encoding? && !value.include?("\0")
        end

        def report_content
          success(payload: @response)
        end
      end
    end
  end
end
