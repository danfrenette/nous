# frozen_string_literal: true

RSpec.describe "Fetch outcomes" do
  it "preserves unexpected extractor errors in detailed failures" do
    url = "https://example.com/"
    stub_request(:get, url).to_return(body: fixture("index.html"), headers: {"content-type" => "text/html"})
    error = RuntimeError.new("extractor defect")
    extractor = double("extractor")
    allow(extractor).to receive(:extract).and_raise(error)

    result = Nous.fetch(url, extractor: extractor, limit: 1, details: true)

    expect(result.pages).to be_empty
    expect(result.failures.first[:error]).to equal(error)
    expect(result.all_succeeded?).to be(false)
  end

  it "retains failures and counts all attempts when an in-flight batch reaches the page limit" do
    root = "https://example.com/"
    stub_request(:get, root).to_return(headers: {"content-type" => "text/html"},
      body: '<html><body><p>Root readable text.</p><a href="/good">Good</a><a href="/bad">Bad</a><a href="/extra">Extra</a></body></html>')
    ["good", "extra"].each do |name|
      stub_request(:get, root + name).to_return(headers: {"content-type" => "text/html"},
        body: "<html><body><p>#{name} readable text.</p></body></html>")
    end
    stub_request(:get, root + "bad").to_return(status: 500)

    result = Nous.fetch(root, limit: 2, concurrency: 3, recursive: true, details: true)
    pages = Nous.fetch(root, limit: 2, concurrency: 3, recursive: true)

    expect(result.pages.map(&:url)).to eq([root, root + "good"])
    expect(pages.map(&:url)).to eq(result.pages.map(&:url))
    expect(result.failures.map { |failure| failure[:requested_url] }).to eq([root + "bad"])
    expect(result.total_requested).to eq(4)
    expect(result.all_succeeded?).to be(false)
    expect(a_request(:get, root + "extra")).to have_been_made.twice
  end
end
