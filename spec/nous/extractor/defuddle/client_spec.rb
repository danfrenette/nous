# frozen_string_literal: true

RSpec.describe Nous::Extractor::Defuddle::Client do
  let(:runner) { Nous::Extractor::Defuddle::RunProcess }

  def extract
    described_class.call(html: "<p>Private content.</p>", url: "https://example.com")
  end

  def respond_with(output)
    allow(runner).to receive(:call).and_return(Nous::Command::Result.new(success: true, payload: output))
  end

  it "passes explicit extraction inputs to the process without changing the HTML" do
    html = "<article>Original content.</article>"
    respond_with('{"title":"Title","content":"<p>Body</p>","markdown":"Body"}')
    result = described_class.call(html: html, url: "https://example.com/final", selector: "article")
    expect(result).to be_success
    expect(result.payload).to eq(title: "Title", content: "<p>Body</p>", markdown: "Body")
    expect(runner).to have_received(:call).with(request: JSON.generate(html: html, url: "https://example.com/final", selector: "article"))
    expect(html).to eq("<article>Original content.</article>")
  end

  it "does not launch work during construction" do
    expect(runner).not_to receive(:call)
    described_class.new(html: "<p>Body</p>", url: "https://example.com")
  end

  it "rejects malformed JSON and invalid response fields" do
    ["not-json", '{"title":4,"content":"body","markdown":"body"}',
      JSON.generate(title: "Title", content: "Body", markdown: "bad\0text")].each do |output|
      respond_with(output)
      expect(extract.error).to be_a(described_class::ProcessError)
    end
  end

  it "rejects invalid input before launching a process without exposing its bytes" do
    expect(runner).not_to receive(:call)
    result = described_class.call(html: "private\xFF".b, url: "https://example.com")
    expect(result).to be_failure
    expect(result.error.message).not_to include("private")
  end

  it "does not turn an empty extraction into success" do
    respond_with('{"title":"Title","content":"","markdown":" "}')
    expect(extract.error).to be_a(described_class::NoContent)
  end

  it "preserves a process failure without parsing its output" do
    error = described_class::ProcessError.new("Defuddle extraction timed out")
    allow(runner).to receive(:call).and_return(Nous::Command::Result.new(success: false, error: error))
    expect(extract.error).to equal(error)
  end
end
