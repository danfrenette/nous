# frozen_string_literal: true

RSpec.describe Nous::ExtractionRunner do
  let(:html) { fixture("index.html") }
  let(:raw_pages) do
    [
      {url: "https://example.com/", pathname: "/", html: html},
      {url: "https://example.com/about", pathname: "/about", html: html}
    ]
  end

  describe "#call" do
    it "extracts all pages" do
      runner = described_class.new(raw_pages:, extractor: Nous::Extractor::Default.new)

      pages = runner.call

      expect(pages.length).to eq(2)
      expect(pages).to all(be_a(Nous::Page))
    end

    it "preserves page order" do
      runner = described_class.new(raw_pages:, extractor: Nous::Extractor::Default.new)

      pages = runner.call

      expect(pages.map(&:url)).to eq(["https://example.com/", "https://example.com/about"])
    end

    it "skips pages that fail extraction" do
      mixed = [
        {url: "https://example.com/good", pathname: "/good", html: html},
        {url: "https://example.com/bad", pathname: "/bad", html: "<html><body></body></html>"},
        {url: "https://example.com/also-good", pathname: "/also-good", html: html}
      ]

      runner = described_class.new(raw_pages: mixed, extractor: Nous::Extractor::Default.new)
      pages = runner.call

      expect(pages.length).to eq(2)
      expect(pages.map(&:url)).to eq(["https://example.com/good", "https://example.com/also-good"])
    end

    it "returns empty array for empty input" do
      runner = described_class.new(raw_pages: [], extractor: Nous::Extractor::Default.new)

      expect(runner.call).to eq([])
    end

    it "clamps concurrency between 1 and 20" do
      runner = described_class.new(raw_pages:, extractor: Nous::Extractor::Default.new, concurrency: 50)

      pages = runner.call

      expect(pages.length).to eq(2)
    end
  end
end
