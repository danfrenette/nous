# frozen_string_literal: true

RSpec.describe Nous::Extractor::Defuddle do
  def record(html)
    Nous::FetchRecord.new(requested_url: "https://example.com/old", final_url: "https://example.com/posts/article",
      pathname: "/posts/article", html: html)
  end

  it "extracts Markdown from acquired HTML, preserving structure and resolving relative links" do
    html = '<html><head><title>Article</title></head><body><nav>Navigation</nav><article><h2>Details</h2><p>A useful article with a <a href="./reference">reference</a>.</p><pre><code class="language-ruby">puts "hello"</code></pre></article><footer>Footer</footer></body></html>'
    result = described_class.new.extract(record(html))
    expect(result).to be_success
    expect(result.payload.title).to eq("Article")
    expect(result.payload.content).to include("Details", "```", 'puts "hello"', "https://example.com/posts/reference")
    expect(result.payload.content).not_to include("Navigation", "Footer")
  end

  it "honors a content selector and falls back when it does not match" do
    html = '<html><body><article><p>Main article.</p></article><section id="chosen"><p>Chosen content.</p></section></body></html>'
    selected = described_class.new(selector: "#chosen").extract(record(html))
    missing = described_class.new(selector: "#missing").extract(record(html))
    expect(selected.payload.content).to include("Chosen content.")
    expect(selected.payload.content).not_to include("Main article.")
    expect(missing).to be_success
  end

  it "decodes meta declarations and BOMs when the response has no charset" do
    html = '<html><head><meta charset="windows-1252"><title>Café</title></head><body><p>Crème.</p></body></html>'
    [html.encode("Windows-1252").b, "\xEF\xBB\xBF".b + html.b].each do |bytes|
      result = described_class.new.extract(record(bytes.freeze))
      expect(result).to be_success
      expect(result.payload.title).to eq("Café")
      expect(result.payload.content).to eq("Crème.")
    end
  end

  it "reports invalid bytes and unsupported charsets as extraction failures" do
    invalid = record("<p>\xFF</p>".b)
    unsupported = record("<p>Body</p>")
    unsupported = unsupported.with(content_type: "text/html; charset=unknown-charset")

    [invalid, unsupported].each do |input|
      result = described_class.new.extract(input)
      expect(result).to be_failure
      expect(result.error).to be_a(Nous::Extractor::ExtractionError)
      expect(result.error.message).to match(/HTML contains invalid encoded bytes|Unsupported HTML charset/)
    end
  end

  it "shares an extractor safely between concurrent calls" do
    extractor = described_class.new
    results = %w[Alpha Bravo].map do |name|
      Thread.new { extractor.extract(record("<html><head><title>#{name}</title></head><body><p>#{name} body.</p></body></html>")) }
    end.map(&:value)
    expect(results.map { |result| result.payload.title }).to eq(%w[Alpha Bravo])
    expect(results.map { |result| result.payload.content }).to eq(["Alpha body.", "Bravo body."])
  end
end
