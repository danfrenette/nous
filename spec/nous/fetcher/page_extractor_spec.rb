# frozen_string_literal: true

RSpec.describe Nous::Fetcher::PageExtractor do
  let(:raw_page) do
    Nous::RawPage.new(
      url: "https://example.com/",
      pathname: "/",
      html: fixture("index.html"),
      requested_url: "https://example.com/",
      content_type: "text/html"
    )
  end
  let(:config) { instance_double(Nous::Configuration, debug?: false) }

  before { allow(Nous).to receive(:configuration).and_return(config) }

  describe ".call" do
    it "returns a successful result with a Page" do
      result = described_class.call(extractor: Nous::Extractor::Default.new, raw_page:)

      expect(result).to be_success
      expect(result.payload).to be_a(Nous::Page)
      expect(result.payload.url).to eq("https://example.com/")
      expect(result.payload.content).to include("main content")
      expect(result.payload.metadata[:requested_url]).to eq("https://example.com/")
      expect(result.payload.metadata[:content_type]).to eq("text/html")
    end

    it "returns a failure result when extraction fails" do
      empty_page = Nous::RawPage.new(
        url: "https://example.com/empty",
        pathname: "/empty",
        html: "<html><body></body></html>",
        requested_url: "https://example.com/empty",
        content_type: "text/html"
      )

      result = described_class.call(extractor: Nous::Extractor::Default.new, raw_page: empty_page)

      expect(result).to be_failure
    end

    it "logs the skip reason when debug" do
      allow(config).to receive(:debug?).and_return(true)

      empty_page = Nous::RawPage.new(
        url: "https://example.com/empty",
        pathname: "/empty",
        html: "<html><body></body></html>",
        requested_url: "https://example.com/empty",
        content_type: "text/html"
      )

      expect {
        described_class.call(extractor: Nous::Extractor::Default.new, raw_page: empty_page)
      }.to output(/extract skip/).to_stderr
    end
  end
end
