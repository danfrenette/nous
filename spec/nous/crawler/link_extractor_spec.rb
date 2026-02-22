# frozen_string_literal: true

RSpec.describe Nous::Crawler::LinkExtractor do
  let(:html) { fixture("index.html") }

  let(:config) { instance_double(Nous::Configuration, match: [], keep_query: false, debug?: false) }

  before { allow(Nous).to receive(:configuration).and_return(config) }

  let(:url_filter) { Nous::Crawler::UrlFilter.new(seed_uri: Nous::Url.new("https://example.com")) }

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

    it "encodes spaces in hrefs" do
      html_with_spaces = '<html><body><a href="/tags/wide events">Link</a></body></html>'
      links = extractor.extract("https://example.com/", html_with_spaces)

      expect(links).to include("https://example.com/tags/wide%20events")
    end
  end
end
