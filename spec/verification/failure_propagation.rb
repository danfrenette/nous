# frozen_string_literal: true

RSpec.describe "Detailed extraction failure readiness" do
  it "FP-1 preserves unreadable originals as visible failures" do
    url = "https://example.com/unreadable"
    stub_request(:get, url).to_return(
      status: 200,
      headers: {"Content-Type" => "text/html; charset=utf-8"},
      body: "<html><body></body></html>"
    )

    result = Nous.fetch(url, limit: 1, details: true)

    expect(result.pages).to be_empty
    aggregate_failures do
      expect(result.failures.map { |failure| failure[:requested_url] }).to include(url)
      expect(result.all_succeeded?).to be(false)
    end
  end
end
