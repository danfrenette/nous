# frozen_string_literal: true

RSpec.describe Nous::Crawler::LinkExtractor do
  let(:html) { fixture("index.html") }

  let(:config) { instance_double(Nous::Configuration, match: [], keep_query: false, verbose?: false) }

  before { allow(Nous).to receive(:configuration).and_return(config) }

  let(:url_filter) { Nous::Crawler::UrlFilter.new(seed_uri: URI.parse("https://example.com")) }

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
