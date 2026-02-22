# frozen_string_literal: true

RSpec.describe Nous::Url do
  describe "#initialize" do
    it "parses a standard URL" do
      url = described_class.new("https://example.com/about")

      expect(url.host).to eq("example.com")
      expect(url.path).to eq("/about")
      expect(url.to_s).to eq("https://example.com/about")
    end

    it "encodes spaces in paths" do
      url = described_class.new("https://example.com/tags/wide events")

      expect(url.path).to eq("/tags/wide%20events")
      expect(url.to_s).to eq("https://example.com/tags/wide%20events")
    end

    it "encodes brackets in paths" do
      url = described_class.new("https://example.com/foo[1]")

      expect(url.path).to eq("/foo%5B1%5D")
    end

    it "does not double-encode already-encoded URLs" do
      url = described_class.new("https://example.com/tags/wide%20events")

      expect(url.path).to eq("/tags/wide%20events")
    end

    it "defaults empty path to /" do
      url = described_class.new("https://example.com")

      expect(url.path).to eq("/")
    end

    it "strips surrounding whitespace" do
      url = described_class.new("  https://example.com/about  ")

      expect(url.to_s).to eq("https://example.com/about")
    end

    it "raises ArgumentError for empty strings" do
      expect { described_class.new("") }.to raise_error(ArgumentError, /invalid URL/)
    end

    it "raises ArgumentError for garbage input" do
      expect { described_class.new("://") }.to raise_error(ArgumentError, /invalid URL/)
    end
  end

  describe "#http?" do
    it "returns true for https" do
      expect(described_class.new("https://example.com/").http?).to be true
    end

    it "returns true for http" do
      expect(described_class.new("http://example.com/").http?).to be true
    end

    it "returns false for ftp" do
      expect(described_class.new("ftp://example.com/file").http?).to be false
    end
  end

  describe "equality" do
    it "considers URLs with the same string equal" do
      a = described_class.new("https://example.com/about")
      b = described_class.new("https://example.com/about")

      expect(a).to eq(b)
      expect(a.hash).to eq(b.hash)
    end

    it "considers different URLs not equal" do
      a = described_class.new("https://example.com/about")
      b = described_class.new("https://example.com/other")

      expect(a).not_to eq(b)
    end
  end
end
