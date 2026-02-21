# frozen_string_literal: true

RSpec.describe Nous::Serializer do
  let(:pages) do
    [
      Nous::Page.new(title: "Page One", url: "https://example.com/one", pathname: "/one", content: "# One"),
      Nous::Page.new(title: "Page Two", url: "https://example.com/two", pathname: "/two", content: "# Two")
    ]
  end

  describe ".call" do
    context "with text format" do
      it "produces XML-tagged output" do
        result = described_class.call(pages:, format: :text)

        expect(result).to be_success
        expect(result.payload).to include("<page>")
        expect(result.payload).to include("<title>Page One</title>")
        expect(result.payload).to include("# One")
      end
    end

    context "with json format" do
      it "produces valid JSON" do
        result = described_class.call(pages:, format: :json)

        expect(result).to be_success

        parsed = JSON.parse(result.payload)
        expect(parsed.length).to eq(2)
        expect(parsed.first["title"]).to eq("Page One")
      end
    end

    context "with unknown format" do
      it "returns a failure" do
        result = described_class.call(pages:, format: :csv)

        expect(result).to be_failure
      end
    end
  end
end
