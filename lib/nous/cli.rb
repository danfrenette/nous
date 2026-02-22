# frozen_string_literal: true

require "optparse"

module Nous
  class Cli
    class CliError < StandardError; end

    def initialize(argv)
      @argv = argv
      @options = {format: :text, concurrency: 3, limit: 100, timeout: 15}
    end

    def run
      parse_options!
      validate!

      pages = Nous.fetch(seed_url, **fetch_options)
      output = Nous.serialize(pages, format: options[:format])
      write_output(output)
    rescue CliError,
      Fetcher::FetchError,
      Serializer::SerializationError => e
      warn("nous: #{e.message}")
      exit 1
    end

    private

    attr_reader :argv, :options

    def seed_url
      argv.first
    end

    def fetch_options
      opts = options.slice(:concurrency, :match, :limit, :timeout, :debug)
      opts[:extractor] = extractor
      opts
    end

    def extractor
      return Extractor::Jina.new if options[:jina]

      Extractor::Default.new(selector: options[:selector])
    end

    def validate!
      raise CliError, "no URL provided. Usage: nous <url> [options]" unless seed_url
    end

    def write_output(output)
      if options[:output]
        File.write(options[:output], output)
      else
        $stdout.puts(output)
      end
    end

    def parse_options!
      parser.parse!(argv)
    rescue OptionParser::InvalidOption => e
      raise CliError, e.message
    end

    def parser
      OptionParser.new do |opts|
        opts.banner = "Usage: nous <url> [options]"

        opts.on("-o", "--output PATH", "Write output to file (default: stdout)") { |v| options[:output] = v }
        opts.on("-f", "--format FORMAT", "Output format: text or json (default: text)") do |v|
          options[:format] = v.to_sym
        end
        opts.on("-c", "--concurrency N", Integer, "Concurrent requests (default: 3)") { |v| options[:concurrency] = v }
        opts.on("-m", "--match PATTERN", "Only include pages matching glob (repeatable)") do |v|
          (options[:match] ||= []) << v
        end
        opts.on("-s", "--selector SELECTOR", "CSS selector to scope extraction") { |v| options[:selector] = v }
        opts.on("-l", "--limit N", Integer, "Maximum pages to fetch") { |v| options[:limit] = v }
        opts.on("--timeout N", Integer, "Per-request timeout in seconds (default: 15)") { |v| options[:timeout] = v }
        opts.on("--jina", "Use Jina Reader API for extraction (handles JS-rendered sites)") { options[:jina] = true }
        opts.on("-d", "--debug", "Debug logging to stderr") { options[:debug] = true }
        opts.on("-v", "--version", "Show version") do
          $stdout.puts("nous #{Nous::VERSION}")
          exit
        end
        opts.on("-h", "--help", "Show help") do
          $stdout.puts(opts)
          exit
        end
      end
    end
  end
end
