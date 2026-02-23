# frozen_string_literal: true

RSpec.describe Nous::Configuration do
  let(:config) { Nous::ConfigurationBuilder.call(**options) }
  let(:options) { {} }

  describe "defaults" do
    it "defaults concurrency to 3" do
      expect(config.concurrency).to eq(3)
    end

    it "defaults limit to 100" do
      expect(config.limit).to eq(100)
    end

    it "defaults timeout to 15" do
      expect(config.timeout).to eq(15)
    end

    it "defaults debug to false" do
      expect(config.debug?).to be false
    end

    it "defaults recursive to false" do
      expect(config.recursive?).to be false
    end

    it "defaults match to empty array" do
      expect(config.match).to eq([])
    end

    it "defaults keep_query to false" do
      expect(config.keep_query).to be false
    end
  end

  describe "coercion" do
    it "clamps concurrency between 1 and 20" do
      expect(Nous::ConfigurationBuilder.call(concurrency: 0).concurrency).to eq(1)
      expect(Nous::ConfigurationBuilder.call(concurrency: 50).concurrency).to eq(20)
    end

    it "clamps limit between 1 and 10_000" do
      expect(Nous::ConfigurationBuilder.call(limit: 0).limit).to eq(1)
      expect(Nous::ConfigurationBuilder.call(limit: 99_999).limit).to eq(10_000)
    end

    it "coerces match to an array" do
      expect(Nous::ConfigurationBuilder.call(match: "/docs/*").match).to eq(["/docs/*"])
    end

    it "respects debug override" do
      expect(Nous::ConfigurationBuilder.call(debug: true).debug?).to be true
    end

    it "respects recursive override" do
      expect(Nous::ConfigurationBuilder.call(recursive: true).recursive?).to be true
    end
  end

  describe "validation" do
    it "raises on unknown options" do
      expect { Nous::ConfigurationBuilder.call(bogus: true) }.to raise_error(
        Nous::ConfigurationBuilder::UnknownOptionError, /bogus/
      )
    end
  end
end
