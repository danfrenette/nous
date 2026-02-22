# frozen_string_literal: true

RSpec.describe Nous::Fetcher::ExtractionThread do
  let(:raw_page) { Nous::RawPage.new(url: "https://example.com/", pathname: "/", html: fixture("index.html")) }
  let(:config) { instance_double(Nous::Configuration, debug?: false) }

  before { allow(Nous).to receive(:configuration).and_return(config) }

  describe "#call" do
    it "returns a Page from a successful extraction" do
      extractor = Nous::Extractor::Default.new
      thread = described_class.new(extractor:, raw_page:)

      result = thread.call

      expect(result).to be_a(Nous::Page)
      expect(result.url).to eq("https://example.com/")
      expect(result.content).to include("main content")
    end

    it "returns nil when extraction fails" do
      empty_page = Nous::RawPage.new(url: "https://example.com/empty", pathname: "/empty", html: "<html><body></body></html>")
      extractor = Nous::Extractor::Default.new
      thread = described_class.new(extractor:, raw_page: empty_page)

      expect(thread.call).to be_nil
    end

    it "logs the skip reason when debug" do
      allow(config).to receive(:debug?).and_return(true)

      empty_page = Nous::RawPage.new(url: "https://example.com/empty", pathname: "/empty", html: "<html><body></body></html>")
      extractor = Nous::Extractor::Default.new
      thread = described_class.new(extractor:, raw_page: empty_page)

      expect { thread.call }.to output(/extract skip/).to_stderr
    end
  end
end
