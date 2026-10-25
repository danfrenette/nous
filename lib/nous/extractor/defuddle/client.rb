# frozen_string_literal: true

require "json"
require "open3"
require "timeout"

module Nous
  module Extractor
    class Defuddle
      class Client < Command
        class NoContent < ExtractionError; end
        class ProcessError < ExtractionError; end

        BRIDGE = File.expand_path("../../../../vendor/defuddle.mjs", __dir__)
        OUTPUT_LIMIT = 64 * 1024 * 1024
        TIMEOUT = 15

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
        rescue Errno::ENOENT
          failure(ProcessError.new("Defuddle requires Node.js 22 or newer on PATH"))
        rescue Timeout::Error
          failure(ProcessError.new("Defuddle extraction timed out"))
        rescue JSON::JSONError, EncodingError, IOError, SystemCallError
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
          Open3.popen3("node", BRIDGE, pgroup: true) do |stdin, stdout, stderr, child|
            workers = []
            begin
              Timeout.timeout(TIMEOUT) do
                workers << Thread.new {
                  stdin.write(request)
                  stdin.close
                }
                workers << Thread.new { read_bounded(stdout, OUTPUT_LIMIT) }
                workers << Thread.new { read_bounded(stderr, 64 * 1024) }
                workers.each { |worker| worker.report_on_exception = false }
                output = workers[1].value
                workers[0].value
                workers[2].value
                raise ProcessError, "Defuddle extraction failed" unless child.value.success?

                @response = JSON.parse(output, symbolize_names: true)
              end
            ensure
              terminate(child.pid)
              [stdin, stdout, stderr].each { |io| io.close unless io.closed? }
              # Preserve the original failure while joining every owned worker.
              workers.each { |worker|
                begin
                  worker.join
                rescue
                  nil
                end
              }
            end
          end
        end

        def terminate(pid)
          Process.kill("KILL", -pid)
        rescue Errno::ESRCH
          nil
        end

        def read_bounded(io, limit)
          output = +""
          loop do
            output << io.readpartial(16 * 1024)
            raise ProcessError, "Defuddle process output exceeds byte limit" if output.bytesize > limit
          end
        rescue EOFError
          output
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
