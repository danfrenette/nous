# frozen_string_literal: true

RSpec.describe Nous::Extractor::Default do
  let(:html) { fixture("index.html") }
  let(:page) { Nous::RawPage.new(url: "https://example.com/", pathname: "/", html: html) }

  describe "#extract" do
    it "returns title and markdown content" do
      result = described_class.new.extract(page)

      expect(result[:title]).to eq("Test Site")
      expect(result[:content]).to include("main content")
    end

    it "respects the selector option" do
      result = described_class.new(selector: "article").extract(page)

      expect(result[:content]).to include("main content")
    end

    it "raises on empty content" do
      empty_page = Nous::RawPage.new(url: "https://example.com/", pathname: "/", html: "<html><body></body></html>")

      expect { described_class.new.extract(empty_page) }.to raise_error(Nous::Extractor::ExtractionError)
    end
  end
end
