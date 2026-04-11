# frozen_string_literal: true

RSpec.describe Nous::Extractor::Default do
  let(:html) { fixture("index.html") }
  let(:raw_page) do
    Nous::RawPage.new(
      url: "https://example.com/",
      pathname: "/",
      html: html,
      requested_url: "https://example.com/",
      content_type: "text/html"
    )
  end

  describe "#extract" do
    it "returns a successful result with extracted content" do
      result = described_class.new.extract(raw_page)

      expect(result).to be_success
      expect(result.payload).to be_a(Nous::ExtractedContent)
      expect(result.payload.title).to eq("Test Site")
      expect(result.payload.content).to include("main content")
    end

    it "respects the selector option" do
      result = described_class.new(selector: "article").extract(raw_page)

      expect(result).to be_success
      expect(result.payload.content).to include("main content")
    end

    it "returns a failure result on empty content" do
      empty_page = Nous::RawPage.new(
        url: "https://example.com/",
        pathname: "/",
        html: "<html><body></body></html>",
        requested_url: "https://example.com/",
        content_type: "text/html"
      )
      result = described_class.new.extract(empty_page)

      expect(result).to be_failure
      expect(result.error).to be_a(Nous::Extractor::ExtractionError)
    end
  end
end
