# frozen_string_literal: true

require "open3"
require "timeout"

module Nous
  module Extractor
    class Defuddle
      class RunProcess < Command
        class Error < ExtractionError; end

        BRIDGE = File.expand_path("../../../../vendor/defuddle.mjs", __dir__)
        OUTPUT_LIMIT = 64 * 1024 * 1024
        TIMEOUT = 15

        def initialize(request:)
          @request = request
        end

        def call
          execute_bridge
          report_output
        rescue Error => error
          failure(error)
        rescue Errno::ENOENT
          failure(Error.new("Defuddle requires Node.js 22 or newer on PATH"))
        rescue Timeout::Error
          failure(Error.new("Defuddle extraction timed out"))
        rescue IOError, SystemCallError
          failure(Error.new("Invalid Defuddle process response"))
        end

        private

        def execute_bridge
          Open3.popen3("node", BRIDGE, pgroup: true) do |stdin, stdout, stderr, child|
            workers = {}
            begin
              Timeout.timeout(TIMEOUT) do
                @output = exchange_content(stdin, stdout, stderr, workers)
                raise Error, "Defuddle extraction failed" unless child.value.success?
              end
            ensure
              terminate(child.pid)
              [stdin, stdout, stderr].each { |io| io.close unless io.closed? }
              workers.each_value { |worker| finish_worker(worker) }
            end
          end
        end

        def exchange_content(stdin, stdout, stderr, workers)
          workers[:input] = start_worker {
            stdin.write(@request)
            stdin.close
          }
          workers[:output] = start_worker { read_bounded(stdout, OUTPUT_LIMIT) }
          workers[:diagnostics] = start_worker { read_bounded(stderr, 64 * 1024) }
          collect_output(workers)
        end

        def collect_output(workers)
          output = workers.fetch(:output).value
          workers.fetch(:input).value
          workers.fetch(:diagnostics).value
          output
        end

        def start_worker(&operation)
          Thread.new do
            Thread.current.report_on_exception = false
            operation.call
          end
        end

        def finish_worker(worker)
          worker.join
        rescue
          # Keep the original failure while joining every owned worker.
          nil
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
            raise Error, "Defuddle process output exceeds byte limit" if output.bytesize > limit
          end
        rescue EOFError
          output
        end

        def report_output
          success(payload: @output)
        end
      end
    end
  end
end
