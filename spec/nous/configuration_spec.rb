# frozen_string_literal: true

RSpec.describe Nous::Configuration do
  describe "#initialize" do
    it "clamps concurrency between 1 and 20" do
      low = described_class.new(concurrency: 0)
      high = described_class.new(concurrency: 50)

      expect(low.concurrency).to eq(1)
      expect(high.concurrency).to eq(20)
    end

    it "clamps limit between 1 and 10_000" do
      low = described_class.new(limit: 0)
      high = described_class.new(limit: 99_999)

      expect(low.limit).to eq(1)
      expect(high.limit).to eq(10_000)
    end

    it "coerces match to an array" do
      config = described_class.new(match: "/docs/*")
      expect(config.match).to eq(["/docs/*"])
    end

    it "defaults verbose to false" do
      config = described_class.new
      expect(config.verbose?).to be false
    end

    it "respects verbose override" do
      config = described_class.new(verbose: true)
      expect(config.verbose?).to be true
    end
  end
end
