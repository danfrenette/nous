# frozen_string_literal: true

RSpec.describe "Full pipeline integration" do
  let(:index_html) { fixture("index.html") }
  let(:about_html) { fixture("about.html") }

  let(:mock_response) do
    Class.new do
      attr_reader :status, :headers

      def initialize(status:, body:, content_type: "text/html; charset=utf-8")
        @status = status
        @body = body
        @headers = {"content-type" => content_type}
      end

      def read = @body

      def close = nil
    end
  end

  let(:responses) do
    {
      "https://example.com/" => mock_response.new(status: 200, body: index_html),
      "https://example.com/about" => mock_response.new(status: 200, body: about_html),
      "https://example.com/guide" => mock_response.new(status: 404, body: ""),
      "https://example.com/nav-link" => mock_response.new(status: 200, body: about_html)
    }
  end

  let(:fake_client) do
    default_response = mock_response.new(status: 404, body: "")
    client_responses = responses

    Class.new do
      define_method(:get) do |url, _headers = {}|
        client_responses.fetch(url) { default_response }
      end

      def close = nil
    end.new
  end

  it "crawls, extracts, and serializes as text" do
    pages = Nous.fetch("https://example.com", http_client: fake_client, limit: 10, concurrency: 2, timeout: 5)

    expect(pages).to be_an(Array)
    expect(pages.length).to be >= 2
    expect(pages).to all(be_a(Nous::Page))

    index_page = pages.find { |p| p.pathname == "/" }
    expect(index_page).not_to be_nil
    expect(index_page.title).to eq("Test Site")
    expect(index_page.content).to include("main content")

    about_page = pages.find { |p| p.pathname == "/about" }
    expect(about_page).not_to be_nil
    expect(about_page.title).to eq("About")
    expect(about_page.content).to include("build things")

    output = Nous.serialize(pages, format: :text)
    expect(output).to include("<page>")
    expect(output).to include("<title>Test Site</title>")
    expect(output).to include("<title>About</title>")
  end

  it "crawls, extracts, and serializes as json" do
    pages = Nous.fetch("https://example.com", http_client: fake_client, limit: 10, concurrency: 2, timeout: 5)
    output = Nous.serialize(pages, format: :json)

    parsed = JSON.parse(output)
    expect(parsed).to be_an(Array)
    expect(parsed.length).to be >= 2

    titles = parsed.map { |p| p["title"] }
    expect(titles).to include("Test Site")
    expect(titles).to include("About")
  end

  it "respects the limit option" do
    pages = Nous.fetch("https://example.com", http_client: fake_client, limit: 1, concurrency: 1, timeout: 5)

    expect(pages.length).to eq(1)
  end

  it "works with the Jina extractor backend" do
    jina_response = {
      "code" => 200,
      "data" => {"title" => "Jina Title", "content" => "# Jina Content\n\nSome text."}
    }.to_json

    stub_request(:get, "https://r.jina.ai/https://example.com/")
      .to_return(status: 200, body: jina_response, headers: {"content-type" => "application/json"})

    stub_request(:get, "https://r.jina.ai/https://example.com/about")
      .to_return(status: 200, body: jina_response, headers: {"content-type" => "application/json"})

    stub_request(:get, "https://r.jina.ai/https://example.com/nav-link")
      .to_return(status: 200, body: jina_response, headers: {"content-type" => "application/json"})

    extractor = Nous::Extractor::Jina.new
    pages = Nous.fetch("https://example.com", http_client: fake_client, limit: 10, concurrency: 2, timeout: 5, extractor: extractor)

    expect(pages).to all(be_a(Nous::Page))
    expect(pages.first.title).to eq("Jina Title")
    expect(pages.first.content).to eq("# Jina Content\n\nSome text.")
  end
end
