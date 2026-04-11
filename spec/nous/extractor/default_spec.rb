# frozen_string_literal: true

RSpec.describe Nous::Extractor::Default do
  let(:html) { fixture("index.html") }
  let(:record) do
    Nous::FetchRecord.new(
      requested_url: "https://example.com/",
      final_url: "https://example.com/",
      pathname: "/",
      html: html,
      content_type: "text/html",
      ok: true,
      error: nil,
      redirected: false
    )
  end

  describe "#extract" do
    it "returns a successful result with extracted content" do
      result = described_class.new.extract(record)

      expect(result).to be_success
      expect(result.payload).to be_a(Nous::ExtractedContent)
      expect(result.payload.title).to eq("Test Site")
      expect(result.payload.content).to include("main content")
    end

    it "respects the selector option" do
      result = described_class.new(selector: "article").extract(record)

      expect(result).to be_success
      expect(result.payload.content).to include("main content")
    end

    it "returns a failure result on empty content" do
      empty_record = Nous::FetchRecord.new(
        requested_url: "https://example.com/",
        final_url: "https://example.com/",
        pathname: "/",
        html: "<html><body></body></html>",
        content_type: "text/html",
        ok: true,
        error: nil,
        redirected: false
      )
      result = described_class.new.extract(empty_record)

      expect(result).to be_failure
      expect(result.error).to be_a(Nous::Extractor::ExtractionError)
    end
  end
end
