# frozen_string_literal: true

RSpec.describe Nous::Crawler::LinkExtractor do
  let(:html) { fixture("index.html") }

  before { Nous.configure(seed_url: "https://example.com") }

  let(:url_filter) { Nous::Crawler::UrlFilter.new(Nous.configuration) }

  subject(:extractor) { described_class.new(url_filter:) }

  describe "#extract" do
    it "returns same-host links" do
      links = extractor.extract("https://example.com/", html)

      expect(links).to include("https://example.com/about")
      expect(links).to include("https://example.com/guide")
      expect(links).to include("https://example.com/nav-link")
    end

    it "excludes external links" do
      links = extractor.extract("https://example.com/", html)

      expect(links).not_to include("https://external.com/page")
    end

    it "excludes mailto and fragment links" do
      links = extractor.extract("https://example.com/", html)

      expect(links.any? { |l| l.include?("mailto") }).to be false
      expect(links.any? { |l| l.include?("#") }).to be false
    end

    it "deduplicates links" do
      links = extractor.extract("https://example.com/", html)

      expect(links.count("https://example.com/about")).to eq(1)
    end
  end
end
