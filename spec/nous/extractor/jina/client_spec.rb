# frozen_string_literal: true

RSpec.describe Nous::Extractor::Jina::Client do
  let(:url) { "https://example.com/test" }
  let(:jina_url) { "https://r.jina.ai/#{url}" }
  let(:json_body) { {data: {title: "Test", content: "Hello"}}.to_json }

  let(:client) { described_class.new(retry_interval: 0) }

  describe "#get" do
    it "returns parsed JSON on success" do
      stub_request(:get, jina_url).to_return(status: 200, body: json_body)

      result = client.get(url)

      expect(result.dig("data", "title")).to eq("Test")
    end

    it "sends correct headers" do
      stub_request(:get, jina_url).to_return(status: 200, body: json_body)

      client.get(url)

      expect(WebMock).to have_requested(:get, jina_url)
        .with(headers: {"Accept" => "application/json", "X-No-Cache" => "true"})
    end

    it "includes authorization when api_key is set" do
      stub_request(:get, jina_url).to_return(status: 200, body: json_body)

      described_class.new(api_key: "sk-test", retry_interval: 0).get(url)

      expect(WebMock).to have_requested(:get, jina_url)
        .with(headers: {"Authorization" => "Bearer sk-test"})
    end

    it "retries on 429 and succeeds" do
      stub_request(:get, jina_url)
        .to_return(status: 429, body: "rate limited")
        .then.to_return(status: 200, body: json_body)

      result = client.get(url)

      expect(result.dig("data", "title")).to eq("Test")
    end

    it "retries on 500 and succeeds" do
      stub_request(:get, jina_url)
        .to_return(status: 500, body: "error")
        .then.to_return(status: 200, body: json_body)

      result = client.get(url)

      expect(result.dig("data", "title")).to eq("Test")
    end

    it "raises after exhausting retries" do
      stub_request(:get, jina_url).to_return(status: 429, body: "rate limited")

      expect { client.get(url) }
        .to raise_error(Nous::Extractor::Jina::Client::Error)
    end

    it "raises on invalid JSON" do
      stub_request(:get, jina_url).to_return(status: 200, body: "not json")

      expect { client.get(url) }
        .to raise_error(Nous::Extractor::Jina::Client::Error, /invalid JSON/)
    end
  end
end
