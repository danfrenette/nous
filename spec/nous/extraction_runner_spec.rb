# frozen_string_literal: true

RSpec.describe Nous::ExtractionRunner do
  let(:html) { fixture("index.html") }
  let(:raw_pages) do
    [
      {url: "https://example.com/", pathname: "/", html: html},
      {url: "https://example.com/about", pathname: "/about", html: html}
    ]
  end
  let(:config) { instance_double(Nous::Configuration, concurrency: 3, verbose?: false) }

  before { allow(Nous).to receive(:configuration).and_return(config) }

  describe ".call" do
    it "extracts all pages" do
      result = described_class.call(raw_pages:, extractor: Nous::Extractor::Default.new)

      expect(result).to be_success
      expect(result.payload.length).to eq(2)
      expect(result.payload).to all(be_a(Nous::Page))
    end

    it "preserves page order" do
      result = described_class.call(raw_pages:, extractor: Nous::Extractor::Default.new)

      expect(result.payload.map(&:url)).to eq(["https://example.com/", "https://example.com/about"])
    end

    it "skips pages that fail extraction" do
      mixed = [
        {url: "https://example.com/good", pathname: "/good", html: html},
        {url: "https://example.com/bad", pathname: "/bad", html: "<html><body></body></html>"},
        {url: "https://example.com/also-good", pathname: "/also-good", html: html}
      ]

      result = described_class.call(raw_pages: mixed, extractor: Nous::Extractor::Default.new)

      expect(result.payload.length).to eq(2)
      expect(result.payload.map(&:url)).to eq(["https://example.com/good", "https://example.com/also-good"])
    end

    it "returns empty array for empty input" do
      result = described_class.call(raw_pages: [], extractor: Nous::Extractor::Default.new)

      expect(result.payload).to eq([])
    end
  end
end
