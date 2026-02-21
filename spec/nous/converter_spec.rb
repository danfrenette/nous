# frozen_string_literal: true

RSpec.describe Nous::Converter do
  describe ".call" do
    it "converts HTML to markdown" do
      result = described_class.call(html: "<h1>Title</h1><p>Body text</p>")

      expect(result).to be_success
      expect(result.payload).to include("# Title")
      expect(result.payload).to include("Body text")
    end

    it "handles code blocks" do
      result = described_class.call(html: "<pre><code>puts 'hello'</code></pre>")

      expect(result).to be_success
      expect(result.payload).to include("puts 'hello'")
    end

    it "strips leading/trailing whitespace" do
      result = described_class.call(html: "  <p>clean</p>  ")

      expect(result.payload).to eq("clean")
    end
  end
end
