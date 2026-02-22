# frozen_string_literal: true

RSpec.describe Nous::UrlResolver do
  let(:base_url) { Nous::Url.new("https://example.com/blog/post") }

  describe ".call" do
    it "resolves a relative path" do
      result = described_class.call(base_url:, href: "/about")

      expect(result).to be_success
      expect(result.payload.to_s).to eq("https://example.com/about")
    end

    it "resolves an absolute URL" do
      result = described_class.call(base_url:, href: "https://example.com/other")

      expect(result).to be_success
      expect(result.payload.to_s).to eq("https://example.com/other")
    end

    it "encodes spaces during resolution" do
      result = described_class.call(base_url:, href: "/tags/cloudflare dev 101")

      expect(result).to be_success
      expect(result.payload.path).to eq("/tags/cloudflare%20dev%20101")
    end

    it "resolves a relative sibling path" do
      result = described_class.call(base_url:, href: "other-post")

      expect(result).to be_success
      expect(result.payload.to_s).to eq("https://example.com/blog/other-post")
    end

    it "returns a failure for unresolvable input" do
      result = described_class.call(base_url:, href: "://broken")

      expect(result).to be_failure
      expect(result.error).to be_a(described_class::ResolutionError)
    end

    it "returns a Url as the payload" do
      result = described_class.call(base_url:, href: "/about")

      expect(result.payload).to be_a(Nous::Url)
    end
  end
end
