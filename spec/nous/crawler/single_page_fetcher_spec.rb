# frozen_string_literal: true

RSpec.describe Nous::Crawler::SinglePageFetcher do
  let(:url) { "https://example.com/blog" }
  let(:config) { instance_double(Nous::Configuration, timeout: 10, debug?: false) }
  let(:connection) { instance_double(Faraday::Connection) }

  before do
    allow(Nous).to receive(:configuration).and_return(config)
  end

  def stub_response(status:, headers: {}, body: "", url: self.url)
    env = instance_double(Faraday::Env, url: URI.parse(url))
    instance_double(Faraday::Response, status:, headers:, body:, env:)
  end

  describe ".call" do
    context "when the page is valid HTML" do
      it "returns a success result with a single-element RawPage array" do
        response = stub_response(status: 200, body: "<html><body>hello</body></html>",
          headers: {"content-type" => "text/html"})
        allow(connection).to receive(:get).with(url).and_return(response)

        result = described_class.call(url:, http_client: connection)

        expect(result).to be_success
        expect(result.payload.length).to eq(1)

        page = result.payload.first
        expect(page).to be_a(Nous::RawPage)
        expect(page.url).to eq(url)
        expect(page.pathname).to eq("/blog")
        expect(page.html).to eq("<html><body>hello</body></html>")
      end
    end

    context "when the response has xhtml content type" do
      it "returns a success result" do
        response = stub_response(status: 200, body: "<html>xhtml</html>",
          headers: {"content-type" => "application/xhtml+xml"})
        allow(connection).to receive(:get).with(url).and_return(response)

        result = described_class.call(url:, http_client: connection)

        expect(result).to be_success
      end
    end

    context "when the connection followed a redirect" do
      it "uses the final URL from the response" do
        final = "https://example.com/blog/"
        response = stub_response(status: 200, body: "<html>redirected</html>",
          headers: {"content-type" => "text/html"}, url: final)
        allow(connection).to receive(:get).with(url).and_return(response)

        result = described_class.call(url:, http_client: connection)

        expect(result).to be_success
        page = result.payload.first
        expect(page.url).to eq(final)
        expect(page.pathname).to eq("/blog/")
      end
    end

    context "when the final URL is on a different host" do
      it "returns a failure result" do
        response = stub_response(status: 200, body: "<html>evil</html>", headers: {"content-type" => "text/html"},
          url: "https://evil.com/phish")
        allow(connection).to receive(:get).with(url).and_return(response)

        result = described_class.call(url:, http_client: connection)

        expect(result).to be_failure
        expect(result.error).to be_a(described_class::FetchError)
        expect(result.error.message).to match(/outside example\.com/)
      end
    end

    context "when the response is not HTML" do
      it "returns a failure result" do
        response = stub_response(status: 200, body: '{"key": "value"}',
          headers: {"content-type" => "application/json"})
        allow(connection).to receive(:get).with(url).and_return(response)

        result = described_class.call(url:, http_client: connection)

        expect(result).to be_failure
        expect(result.error).to be_a(described_class::FetchError)
        expect(result.error.message).to match(/non-html content/)
      end
    end

    context "when Faraday raises an error" do
      it "returns a failure result" do
        allow(connection).to receive(:get).with(url).and_raise(Faraday::ConnectionFailed.new("connection refused"))

        result = described_class.call(url:, http_client: connection)

        expect(result).to be_failure
        expect(result.error).to be_a(described_class::FetchError)
      end
    end

    context "when Faraday raises a timeout error" do
      it "returns a failure result" do
        allow(connection).to receive(:get).with(url).and_raise(Faraday::TimeoutError.new("timeout"))

        result = described_class.call(url:, http_client: connection)

        expect(result).to be_failure
        expect(result.error).to be_a(described_class::FetchError)
      end
    end
  end
end
