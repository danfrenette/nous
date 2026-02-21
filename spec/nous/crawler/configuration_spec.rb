# frozen_string_literal: true

RSpec.describe Nous::Crawler::Configuration do
  describe "#initialize" do
    it "parses a valid seed URL" do
      config = described_class.new(seed_url: "https://example.com")
      expect(config.seed.host).to eq("example.com")
    end

    it "raises on non-http seed URL" do
      expect do
        described_class.new(seed_url: "ftp://example.com")
      end.to raise_error(Nous::Crawler::Error, /http or https/)
    end

    it "raises on invalid URI" do
      expect do
        described_class.new(seed_url: "not a url at all :::")
      end.to raise_error(Nous::Crawler::Error, /invalid seed URL/)
    end

    it "clamps concurrency between 1 and 20" do
      low = described_class.new(seed_url: "https://example.com", concurrency: 0)
      high = described_class.new(seed_url: "https://example.com", concurrency: 50)

      expect(low.concurrency).to eq(1)
      expect(high.concurrency).to eq(20)
    end

    it "clamps limit between 1 and 10_000" do
      low = described_class.new(seed_url: "https://example.com", limit: 0)
      high = described_class.new(seed_url: "https://example.com", limit: 99_999)

      expect(low.limit).to eq(1)
      expect(high.limit).to eq(10_000)
    end

    it "coerces match to an array" do
      config = described_class.new(seed_url: "https://example.com", match: "/docs/*")
      expect(config.match).to eq(["/docs/*"])
    end
  end
end
