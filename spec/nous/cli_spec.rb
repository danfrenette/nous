# frozen_string_literal: true

require "tmpdir"

RSpec.describe Nous::Cli do
  let(:pages) do
    [Nous::Page.new(title: "Test", url: "https://example.com/", pathname: "/", content: "# Hello")]
  end

  let(:serialized_output) { "<page><title>Test</title><content># Hello</content></page>" }

  before do
    allow(Nous).to receive(:fetch).and_return(pages)
    allow(Nous).to receive(:serialize).and_return(serialized_output)
  end

  def run_cli(*args)
    cli = described_class.new(args.flatten)
    cli.run
  end

  describe "successful run" do
    it "fetches and serializes to stdout" do
      expect { run_cli("https://example.com") }.to output(/Test/).to_stdout

      expect(Nous).to have_received(:fetch).with(
        "https://example.com",
        hash_including(concurrency: 3, limit: 100, timeout: 15)
      )
      expect(Nous).to have_received(:serialize).with(pages, format: :text)
    end

    it "passes concurrency option" do
      expect { run_cli("https://example.com", "-c", "10") }.to output.to_stdout

      expect(Nous).to have_received(:fetch).with(
        "https://example.com",
        hash_including(concurrency: 10)
      )
    end

    it "passes limit option" do
      expect { run_cli("https://example.com", "-l", "5") }.to output.to_stdout

      expect(Nous).to have_received(:fetch).with(
        "https://example.com",
        hash_including(limit: 5)
      )
    end

    it "passes timeout option" do
      expect { run_cli("https://example.com", "--timeout", "30") }.to output.to_stdout

      expect(Nous).to have_received(:fetch).with(
        "https://example.com",
        hash_including(timeout: 30)
      )
    end

    it "passes match patterns" do
      expect { run_cli("https://example.com", "-m", "/blog/*", "-m", "/docs/*") }.to output.to_stdout

      expect(Nous).to have_received(:fetch).with(
        "https://example.com",
        hash_including(match: ["/blog/*", "/docs/*"])
      )
    end

    it "passes format option" do
      expect { run_cli("https://example.com", "-f", "json") }.to output.to_stdout

      expect(Nous).to have_received(:serialize).with(pages, format: :json)
    end

    it "passes debug flag" do
      expect { run_cli("https://example.com", "-d") }.to output.to_stdout

      expect(Nous).to have_received(:fetch).with(
        "https://example.com",
        hash_including(debug: true)
      )
    end
  end

  describe "extractor selection" do
    it "uses Default extractor by default" do
      expect { run_cli("https://example.com") }.to output.to_stdout

      expect(Nous).to have_received(:fetch) do |_url, **opts|
        expect(opts[:extractor]).to be_a(Nous::Extractor::Default)
      end
    end

    it "uses Jina extractor with --jina flag" do
      expect { run_cli("https://example.com", "--jina") }.to output.to_stdout

      expect(Nous).to have_received(:fetch) do |_url, **opts|
        expect(opts[:extractor]).to be_a(Nous::Extractor::Jina)
      end
    end

    it "passes selector to Default extractor" do
      expect { run_cli("https://example.com", "-s", "article.main") }.to output.to_stdout

      expect(Nous).to have_received(:fetch) do |_url, **opts|
        extractor = opts[:extractor]
        expect(extractor).to be_a(Nous::Extractor::Default)
      end
    end
  end

  describe "output destination" do
    it "writes to file with -o flag" do
      tmpfile = File.join(Dir.tmpdir, "nous_test_#{Process.pid}.txt")

      begin
        run_cli("https://example.com", "-o", tmpfile)

        expect(File.read(tmpfile)).to eq(serialized_output)
      ensure
        File.delete(tmpfile) if File.exist?(tmpfile)
      end
    end
  end

  describe "error handling" do
    it "exits with error when no URL provided" do
      expect do
        expect { run_cli }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      end.to output(/no URL provided/).to_stderr
    end

    it "exits with error on invalid option" do
      expect do
        expect { run_cli("https://example.com", "--bogus") }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      end.to output(/invalid option/).to_stderr
    end

    it "exits with error when fetch fails" do
      allow(Nous).to receive(:fetch).and_raise(Nous::Fetcher::FetchError, "connection refused")

      expect do
        expect { run_cli("https://example.com") }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      end.to output(/connection refused/).to_stderr
    end
  end

  describe "--help" do
    it "prints usage and exits" do
      expect do
        expect { run_cli("--help") }.to raise_error(SystemExit) { |e| expect(e.status).to eq(0) }
      end.to output(/Usage: nous/).to_stdout
    end
  end

  describe "--version" do
    it "prints version and exits with --version" do
      expect do
        expect { run_cli("--version") }.to raise_error(SystemExit) { |e| expect(e.status).to eq(0) }
      end.to output(/nous #{Nous::VERSION}/o).to_stdout
    end

    it "prints version and exits with -v" do
      expect do
        expect { run_cli("-v") }.to raise_error(SystemExit) { |e| expect(e.status).to eq(0) }
      end.to output(/nous #{Nous::VERSION}/o).to_stdout
    end
  end
end
