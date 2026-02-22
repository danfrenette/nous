# frozen_string_literal: true

RSpec.describe Nous::Crawler::RedirectFollower do
  let(:seed_host) { "example.com" }
  let(:url) { "https://example.com/blog/post" }
  let(:client) { instance_double("Async::HTTP::Internet") }

  def stub_response(status:, headers: {}, body: "")
    instance_double("Async::HTTP::Response", status:, headers:, read: body, close: nil)
  end

  describe ".call" do
    context "when the response is not a redirect" do
      it "returns the response and final url" do
        response = stub_response(status: 200)
        allow(client).to receive(:get).with(url, {}).and_return(response)

        result = described_class.call(client:, seed_host:, url:)

        expect(result).to be_success
        returned_response, final_url = result.payload
        expect(returned_response).to eq(response)
        expect(final_url.to_s).to eq(url)
      end
    end

    context "with a single redirect" do
      it "follows the redirect and returns the final response" do
        redirect = stub_response(status: 307, headers: {"location" => "https://example.com/blog/post/"})
        final = stub_response(status: 200)

        allow(client).to receive(:get).with(url, {}).and_return(redirect)
        allow(client).to receive(:get).with("https://example.com/blog/post/", {}).and_return(final)

        result = described_class.call(client:, seed_host:, url:)

        expect(result).to be_success
        returned_response, final_url = result.payload
        expect(returned_response).to eq(final)
        expect(final_url.to_s).to eq("https://example.com/blog/post/")
      end
    end

    context "with a chain of redirects" do
      it "follows each hop" do
        first = stub_response(status: 301, headers: {"location" => "/step-2"})
        second = stub_response(status: 302, headers: {"location" => "/step-3"})
        final = stub_response(status: 200)

        allow(client).to receive(:get).with(url, {}).and_return(first)
        allow(client).to receive(:get).with("https://example.com/step-2", {}).and_return(second)
        allow(client).to receive(:get).with("https://example.com/step-3", {}).and_return(final)

        result = described_class.call(client:, seed_host:, url:)

        expect(result).to be_success
        _, final_url = result.payload
        expect(final_url.to_s).to eq("https://example.com/step-3")
      end
    end

    context "with a relative location header" do
      it "resolves against the current url" do
        redirect = stub_response(status: 307, headers: {"location" => "/new-path"})
        final = stub_response(status: 200)

        allow(client).to receive(:get).with(url, {}).and_return(redirect)
        allow(client).to receive(:get).with("https://example.com/new-path", {}).and_return(final)

        result = described_class.call(client:, seed_host:, url:)

        expect(result).to be_success
        _, final_url = result.payload
        expect(final_url.to_s).to eq("https://example.com/new-path")
      end
    end

    context "when too many redirects" do
      it "returns a failure with RedirectError" do
        redirect = stub_response(status: 301, headers: {"location" => url})
        allow(client).to receive(:get).with(url, {}).and_return(redirect)

        result = described_class.call(client:, seed_host:, url:, hops_remaining: 0)

        expect(result).to be_failure
        expect(result.error).to be_a(described_class::RedirectError)
        expect(result.error.message).to match(/too many redirects/)
      end
    end

    context "when redirect to a different host" do
      it "returns a failure with RedirectError" do
        redirect = stub_response(status: 301, headers: {"location" => "https://evil.com/phish"})
        allow(client).to receive(:get).with(url, {}).and_return(redirect)

        result = described_class.call(client:, seed_host:, url:)

        expect(result).to be_failure
        expect(result.error).to be_a(described_class::RedirectError)
        expect(result.error.message).to match(/outside example\.com/)
      end
    end

    context "when redirect to a non-http scheme" do
      it "returns a failure with RedirectError" do
        redirect = stub_response(status: 301, headers: {"location" => "ftp://example.com/file"})
        allow(client).to receive(:get).with(url, {}).and_return(redirect)

        result = described_class.call(client:, seed_host:, url:)

        expect(result).to be_failure
        expect(result.error).to be_a(described_class::RedirectError)
      end
    end

    context "when redirect has no location header" do
      it "returns a failure with RedirectError" do
        redirect = stub_response(status: 301, headers: {})
        allow(client).to receive(:get).with(url, {}).and_return(redirect)

        result = described_class.call(client:, seed_host:, url:)

        expect(result).to be_failure
        expect(result.error).to be_a(described_class::RedirectError)
        expect(result.error.message).to match(/without location/)
      end
    end
  end
end
