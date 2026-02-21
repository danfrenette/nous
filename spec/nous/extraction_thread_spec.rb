# frozen_string_literal: true

RSpec.describe Nous::ExtractionThread do
  let(:raw_page) { {url: "https://example.com/", pathname: "/", html: fixture("index.html")} }

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
      empty_page = {url: "https://example.com/empty", pathname: "/empty", html: "<html><body></body></html>"}
      extractor = Nous::Extractor::Default.new
      thread = described_class.new(extractor:, raw_page: empty_page)

      expect(thread.call).to be_nil
    end

    it "logs the skip reason when verbose" do
      empty_page = {url: "https://example.com/empty", pathname: "/empty", html: "<html><body></body></html>"}
      extractor = Nous::Extractor::Default.new
      thread = described_class.new(extractor:, raw_page: empty_page, verbose: true)

      expect { thread.call }.to output(/extract skip/).to_stderr
    end
  end
end
