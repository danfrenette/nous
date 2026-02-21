# frozen_string_literal: true

RSpec.describe Nous::Extractor do
  let(:html) { fixture("index.html") }

  describe ".call" do
    it "extracts readable content" do
      result = described_class.call(html:)

      expect(result).to be_success
      expect(result.payload[:title]).to eq("Test Site")
      expect(result.payload[:content]).to include("main content")
    end

    it "strips script tags" do
      result = described_class.call(html:)

      expect(result.payload[:content]).not_to include("alert")
    end

    it "strips nav and footer" do
      result = described_class.call(html:)

      expect(result.payload[:content]).not_to include("Footer content")
    end

    context "with a CSS selector" do
      it "scopes extraction to the selector" do
        result = described_class.call(html:, selector: "article")

        expect(result).to be_success
        expect(result.payload[:content]).to include("main content")
      end
    end

    context "when readability returns nil" do
      it "returns a failure result" do
        result = described_class.call(html: "<html><body></body></html>")

        expect(result).to be_failure
      end
    end
  end
end
