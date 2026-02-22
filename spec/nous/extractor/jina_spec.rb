# frozen_string_literal: true

RSpec.describe Nous::Extractor::Jina do
  let(:page) { Nous::RawPage.new(url: "https://example.com/test", pathname: "/test", html: "<html></html>") }
  let(:jina_response) do
    {
      code: 200,
      status: 20_000,
      data: {
        title: "Test Article",
        content: "# Hello\n\nSome markdown content.",
        url: "https://example.com/test"
      }
    }.to_json
  end

  before do
    stub_request(:get, "https://r.jina.ai/https://example.com/test")
      .to_return(status: 200, body: jina_response, headers: {"Content-Type" => "application/json"})
  end

  let(:extractor) { described_class.new(retry_interval: 0) }

  describe "#extract" do
    it "returns title and markdown content from Jina API" do
      result = extractor.extract(page)

      expect(result[:title]).to eq("Test Article")
      expect(result[:content]).to eq("# Hello\n\nSome markdown content.")
    end

    it "sends the correct headers" do
      extractor.extract(page)

      expect(WebMock).to have_requested(:get, "https://r.jina.ai/https://example.com/test")
        .with(headers: {"Accept" => "application/json", "X-No-Cache" => "true"})
    end

    it "includes authorization header when api_key is provided" do
      described_class.new(api_key: "test-key", retry_interval: 0).extract(page)

      expect(WebMock).to have_requested(:get, "https://r.jina.ai/https://example.com/test")
        .with(headers: {"Authorization" => "Bearer test-key"})
    end

    it "raises on non-200 response" do
      stub_request(:get, "https://r.jina.ai/https://example.com/test")
        .to_return(status: 429, body: "rate limited")

      expect { extractor.extract(page) }
        .to raise_error(Nous::Extractor::ExtractionError)
    end

    it "raises on invalid JSON" do
      stub_request(:get, "https://r.jina.ai/https://example.com/test")
        .to_return(status: 200, body: "not json")

      expect { extractor.extract(page) }
        .to raise_error(Nous::Extractor::ExtractionError, /invalid JSON/)
    end
  end
end
