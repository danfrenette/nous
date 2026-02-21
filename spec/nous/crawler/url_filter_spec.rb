# frozen_string_literal: true

RSpec.describe Nous::Crawler::UrlFilter do
  let(:config) do
    Nous::Crawler::Configuration.new(seed_url: "https://example.com/docs")
  end

  subject(:filter) { described_class.new(config) }

  describe "#canonicalize" do
    it "strips fragments" do
      uri = URI.parse("https://example.com/page#section")
      expect(filter.canonicalize(uri)).to eq("https://example.com/page")
    end

    it "strips query strings by default" do
      uri = URI.parse("https://example.com/page?v=1")
      expect(filter.canonicalize(uri)).to eq("https://example.com/page")
    end

    it "preserves query strings when configured" do
      config = Nous::Crawler::Configuration.new(seed_url: "https://example.com", keep_query: true)
      filter = described_class.new(config)
      uri = URI.parse("https://example.com/page?v=1")

      expect(filter.canonicalize(uri)).to eq("https://example.com/page?v=1")
    end

    it "defaults empty path to /" do
      uri = URI.parse("https://example.com")
      expect(filter.canonicalize(uri)).to eq("https://example.com/")
    end
  end

  describe "#allowed?" do
    it "rejects empty strings" do
      expect(filter.allowed?("")).to be false
    end

    it "rejects mailto links" do
      expect(filter.allowed?("mailto:a@b.com")).to be false
    end

    it "rejects javascript links" do
      expect(filter.allowed?("javascript:void(0)")).to be false
    end

    it "rejects tel links" do
      expect(filter.allowed?("tel:123")).to be false
    end

    it "accepts normal paths" do
      expect(filter.allowed?("/about")).to be true
    end
  end

  describe "#same_host?" do
    it "accepts same host" do
      uri = URI.parse("https://example.com/other")
      expect(filter.same_host?(uri)).to be true
    end

    it "rejects different host" do
      uri = URI.parse("https://other.com/page")
      expect(filter.same_host?(uri)).to be false
    end

    it "rejects non-HTTP URIs" do
      uri = URI.parse("ftp://example.com/file")
      expect(filter.same_host?(uri)).to be false
    end
  end

  describe "#matches_path?" do
    it "matches everything when no patterns set" do
      expect(filter.matches_path?("/anything")).to be true
    end

    context "with match patterns" do
      let(:config) do
        Nous::Crawler::Configuration.new(seed_url: "https://example.com", match: ["/docs/*"])
      end

      it "includes matching paths" do
        expect(filter.matches_path?("/docs/intro")).to be true
      end

      it "excludes non-matching paths" do
        expect(filter.matches_path?("/blog/post")).to be false
      end
    end
  end
end
