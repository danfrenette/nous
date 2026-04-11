# frozen_string_literal: true

RSpec.describe Nous::Fetcher::PageExtractor do
  let(:record) do
    Nous::FetchRecord.new(
      requested_url: "https://example.com/",
      final_url: "https://example.com/",
      pathname: "/",
      html: fixture("index.html"),
      content_type: "text/html",
      ok: true,
      error: nil,
      redirected: false
    )
  end
  let(:config) { instance_double(Nous::Configuration, debug?: false) }

  before { allow(Nous).to receive(:configuration).and_return(config) }

  describe ".call" do
    it "returns a successful result with a Page" do
      result = described_class.call(extractor: Nous::Extractor::Default.new, record:)

      expect(result).to be_success
      expect(result.payload).to be_a(Nous::Page)
      expect(result.payload.url).to eq("https://example.com/")
      expect(result.payload.content).to include("main content")
      expect(result.payload.metadata[:requested_url]).to eq("https://example.com/")
      expect(result.payload.metadata[:content_type]).to eq("text/html")
    end

    it "returns a failure result when extraction fails" do
      empty_record = Nous::FetchRecord.new(
        requested_url: "https://example.com/empty",
        final_url: "https://example.com/empty",
        pathname: "/empty",
        html: "<html><body></body></html>",
        content_type: "text/html",
        ok: true,
        error: nil,
        redirected: false
      )

      result = described_class.call(extractor: Nous::Extractor::Default.new, record: empty_record)

      expect(result).to be_failure
    end

    it "logs the skip reason when debug" do
      allow(config).to receive(:debug?).and_return(true)

      empty_record = Nous::FetchRecord.new(
        requested_url: "https://example.com/empty",
        final_url: "https://example.com/empty",
        pathname: "/empty",
        html: "<html><body></body></html>",
        content_type: "text/html",
        ok: true,
        error: nil,
        redirected: false
      )

      expect {
        described_class.call(extractor: Nous::Extractor::Default.new, record: empty_record)
      }.to output(/extract skip/).to_stderr
    end
  end
end
