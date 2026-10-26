# frozen_string_literal: true

RSpec.describe "Full pipeline integration" do
  let(:index_html) { fixture("index.html") }
  let(:about_html) { fixture("about.html") }

  context "with recursive crawling" do
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

    it "resolves the fetch mode at execution instead of construction" do
      responses["https://example.com/"] = mock_response.new(status: 404, body: "")
      Nous.reset_configuration!
      fetcher = Nous::Fetcher.new(seed_url: "https://example.com/", http_client: fake_client)
      Nous.configure(recursive: true, limit: 1)

      result = fetcher.call

      expect(result).to be_success
      expect(result.payload).to eq([])
    end

    it "uses the current mode after configuration changes" do
      responses["https://example.com/"] = mock_response.new(status: 404, body: "")
      Nous.configure(limit: 1)
      fetcher = Nous::Fetcher.new(seed_url: "https://example.com/", http_client: fake_client)
      Nous.configure(recursive: true, limit: 1)

      expect(fetcher.call.payload).to eq([])
    end

    it "decodes raw acquired bytes using the response charset" do
      html = '<html><head><meta charset="utf-8"><title>Café</title></head><body><p>Crème brûlée.</p></body></html>'.encode("Windows-1252").b.freeze
      responses["https://example.com/"] = mock_response.new(status: 200, body: html,
        content_type: "text/html; charset=windows-1252")

      result = Nous.fetch("https://example.com", http_client: fake_client,
        recursive: true, limit: 1, details: true)

      expect(result.failures).to be_empty
      expect(result.pages.first.title).to eq("Café")
      expect(result.pages.first.content).to eq("Crème brûlée.")
      expect(html.encoding).to eq(Encoding::BINARY)
    end

    it "reports acquisition and extraction failures while retaining readable page order" do
      responses["https://example.com/about"] = mock_response.new(status: 200, body: "<html><body></body></html>")

      detailed = Nous.fetch("https://example.com", http_client: fake_client, limit: 10,
        concurrency: 2, recursive: true, details: true)
      pages = Nous.fetch("https://example.com", http_client: fake_client, limit: 10,
        concurrency: 2, recursive: true)

      expect(detailed.pages.map(&:url)).to eq(pages.map(&:url))
      expect(detailed.pages.map(&:pathname)).to eq(["/", "/nav-link"])
      expect(detailed.failures.map { |failure| failure[:requested_url] }).to contain_exactly(
        "https://example.com/guide", "https://example.com/about"
      )
      expect(detailed.all_succeeded?).to be(false)
      extraction_failure = detailed.failures.find { |failure| failure[:requested_url].end_with?("/about") }
      expect(extraction_failure[:error]).to be_a(Nous::Extractor::ExtractionError)
      expect(detailed.total_requested).to eq(4)
    end

    it "crawls, extracts, and serializes as text" do
      pages = Nous.fetch("https://example.com", http_client: fake_client, limit: 10, concurrency: 2, timeout: 5,
        recursive: true)

      expect(pages).to be_an(Array)
      expect(pages.length).to be >= 2
      expect(pages).to all(be_a(Nous::Page))

      index_page = pages.find { |p| p.pathname == "/" }
      expect(index_page).not_to be_nil
      expect(index_page.title).to eq("Test Site")
      expect(index_page.content).to include("main content")
      expect(index_page.metadata[:extractor]).to eq("Nous::Extractor::Defuddle")
      expect(index_page.metadata[:requested_url]).to eq("https://example.com/")
      expect(index_page.metadata[:content_type]).to eq("text/html; charset=utf-8")

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
      pages = Nous.fetch("https://example.com", http_client: fake_client, limit: 10, concurrency: 2, timeout: 5,
        recursive: true)
      output = Nous.serialize(pages, format: :json)

      parsed = JSON.parse(output)
      expect(parsed).to be_an(Array)
      expect(parsed.length).to be >= 2

      titles = parsed.map { |p| p["title"] }
      expect(titles).to include("Test Site")
      expect(titles).to include("About")

      index = parsed.find { |p| p["pathname"] == "/" }
      expect(index["metadata"]["extractor"]).to eq("Nous::Extractor::Defuddle")
      expect(index["metadata"]["requested_url"]).to eq("https://example.com/")
    end

    it "respects the limit option" do
      pages = Nous.fetch("https://example.com", http_client: fake_client, limit: 1, concurrency: 1, timeout: 5,
        recursive: true)

      expect(pages.length).to eq(1)
    end

    it "supports the explicit Readability backup" do
      pages = Nous.fetch("https://example.com", http_client: fake_client,
        extractor: Nous::Extractor::Default.new, recursive: true)
      expect(pages.first.content).to include("main content")
      expect(pages.first.metadata[:extractor]).to eq("Nous::Extractor::Default")
    end
  end

  context "with single-page fetch (default)" do
    it "fetches and extracts a single page" do
      stub_request(:get, "https://example.com/blog")
        .to_return(status: 200, body: index_html, headers: {"content-type" => "text/html"})

      pages = Nous.fetch("https://example.com/blog", timeout: 5)

      expect(pages).to be_an(Array)
      expect(pages.length).to eq(1)
      expect(pages.first).to be_a(Nous::Page)
      expect(pages.first.title).to eq("Test Site")
      expect(pages.first.pathname).to eq("/blog")
    end

    it "serializes a single page as text" do
      stub_request(:get, "https://example.com/blog")
        .to_return(status: 200, body: index_html, headers: {"content-type" => "text/html"})

      pages = Nous.fetch("https://example.com/blog", timeout: 5)
      output = Nous.serialize(pages, format: :text)

      expect(output).to include("<page>")
      expect(output).to include("<title>Test Site</title>")
    end
  end

  context "with details option" do
    it "returns FetchResult with pages and failures for single-page" do
      stub_request(:get, "https://example.com/blog")
        .to_return(status: 200, body: index_html, headers: {"content-type" => "text/html"})

      result = Nous.fetch("https://example.com/blog", timeout: 5, details: true)

      expect(result).to be_a(Nous::FetchResult)
      expect(result.pages).to be_an(Array)
      expect(result.pages.length).to eq(1)
      expect(result.failures).to eq([])
      expect(result.all_succeeded?).to be true
      expect(result.any_succeeded?).to be true
      expect(result.total_requested).to eq(1)
    end

    it "returns FetchResult with failure for non-HTML content without raising" do
      stub_request(:get, "https://example.com/api")
        .to_return(status: 200, body: '{"key": "value"}', headers: {"content-type" => "application/json"})

      result = Nous.fetch("https://example.com/api", timeout: 5, details: true)

      expect(result).to be_a(Nous::FetchResult)
      expect(result.pages).to be_empty
      expect(result.failures).not_to be_empty
      expect(result.failures.first[:requested_url]).to eq("https://example.com/api")
      expect(result.failures.first[:error]).to include("non-html")
      expect(result.all_succeeded?).to be false
      expect(result.any_succeeded?).to be false
    end

    it "returns FetchResult with mixed results for recursive crawl" do
      stub_request(:get, "https://example.com/")
        .to_return(status: 200, body: index_html, headers: {"content-type" => "text/html"})

      stub_request(:get, "https://example.com/about")
        .to_return(status: 404, body: "not found")

      stub_request(:get, "https://example.com/nav-link")
        .to_return(status: 200, body: about_html, headers: {"content-type" => "text/html"})

      stub_request(:get, "https://example.com/guide")
        .to_return(status: 404, body: "not found")

      result = Nous.fetch("https://example.com", recursive: true, limit: 3, details: true)

      expect(result).to be_a(Nous::FetchResult)
      expect(result.pages).not_to be_empty
      expect(result.any_succeeded?).to be true
      expect(result.total_requested).to be > 0
    end
  end
end
