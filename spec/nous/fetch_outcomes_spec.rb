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
end
