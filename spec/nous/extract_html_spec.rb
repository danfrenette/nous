# frozen_string_literal: true

RSpec.describe "Retained HTML extraction" do
  it "extracts saved content and provenance without fetching or changing the bytes" do
    html = fixture("index.html").b.freeze
    result = Nous::ExtractHtml.call(html: html, source_url: "https://example.com/saved")

    expect(result).to be_success
    expect(result.payload.title).to eq("Test Site")
    expect(result.payload.content).to include("Welcome", "main content")
    expect(result.metadata).to include(source_url: "https://example.com/saved", content_type: "text/html",
      encoding: "UTF-8", format: :markdown)
    expect(html).to eq(fixture("index.html").b)
  end

  it "offers plain text with separated readable blocks" do
    result = Nous::ExtractHtml.call(html: fixture("index.html"), source_url: "https://example.com/saved", format: :text)

    expect(result).to be_success
    expect(result.payload.content).to include("Welcome", "This is the main content.")
    expect(result.payload.content).not_to include("<", "\n\n")
    expect(result.metadata[:format]).to eq(:text)
  end

  it "decodes the declared charset ahead of conflicting HTML metadata" do
    html = '<html><head><meta charset="utf-8"><title>Café</title></head><body><article><p>Café déjà vu.</p></article></body></html>'.encode("ISO-8859-1").b.freeze
    result = Nous::ExtractHtml.call(html: html, source_url: "https://example.com/saved", content_type: "text/html; charset=iso-8859-1")

    expect(result).to be_success
    expect(result.payload.title).to eq("Café")
    expect(result.payload.content).to include("Café déjà vu.")
    expect(result.metadata[:encoding]).to eq("ISO-8859-1")
    expect(result.payload.content.encoding).to eq(Encoding::UTF_8)
  end

  it "rejects invalid and unreadable retained content with stable errors" do
    invalid = Nous::ExtractHtml.call(html: "bad\xFF".b, source_url: "saved")
    nul = Nous::ExtractHtml.call(html: "bad\0content", source_url: "saved")
    empty = Nous::ExtractHtml.call(html: "<html><body></body></html>", source_url: "saved")

    expect(invalid.error).to be_a(Nous::ExtractHtml::InvalidContent)
    expect(nul.error).to be_a(Nous::ExtractHtml::InvalidContent)
    expect(empty.error).to be_a(Nous::ExtractHtml::NoContent)
    expect([invalid, nul, empty]).to all(be_failure)
  end

  it "rejects unsupported formats, media types and charsets explicitly" do
    options = [{format: :xml}, {content_type: "application/json"}, {content_type: "text/html; charset=imaginary"}]
    options.each do |option|
      result = Nous::ExtractHtml.call(html: fixture("index.html"), source_url: "saved", **option)
      expect(result).to be_failure
      expect(result.error).to be_a(Nous::ExtractHtml::UnsupportedContent)
    end
  end

  it "enforces input and UTF-8 output byte budgets" do
    html = "<html><body><article><p>Café déjà vu.</p></article></body></html>"
    input_failure = Nous::ExtractHtml.call(html: html, source_url: "saved", max_input_bytes: html.bytesize - 1)
    output_failure = Nous::ExtractHtml.call(html: html, source_url: "saved", format: :text, max_output_bytes: 13)
    exact = Nous::ExtractHtml.call(html: html, source_url: "saved", format: :text,
      max_input_bytes: html.bytesize, max_output_bytes: "Café déjà vu.".bytesize)

    expect(input_failure.error).to be_a(Nous::ExtractHtml::InputLimitExceeded)
    expect(output_failure.error).to be_a(Nous::ExtractHtml::OutputLimitExceeded)
    expect(exact).to be_success
    expect(exact.payload.content).to eq("Café déjà vu.")
  end

  it "requires positive integer byte budgets" do
    [0, -1, nil, 1.5].each do |limit|
      result = Nous::ExtractHtml.call(html: "saved", source_url: "saved", max_input_bytes: limit)
      expect(result.error).to be_a(ArgumentError)
    end
  end

  it "uses BOM then HTML meta then UTF-8 when no header charset exists" do
    markup = "<html><head><title>Café</title></head><body><p>Café déjà vu.</p></body></html>"
    bom_html = "\xFF\xFE".b + markup.encode("UTF-16LE").b
    meta_html = markup.sub("<head>", '<head><meta charset="windows-1252">').encode("Windows-1252").b
    [[bom_html, "UTF-16LE"], [meta_html, "Windows-1252"], [markup.b, "UTF-8"]].each do |html, encoding|
      result = Nous::ExtractHtml.call(html: html.freeze, source_url: "saved")
      expect(result).to be_success
      expect(result.payload.content).to include("Café déjà vu.")
      expect(result.metadata[:encoding]).to eq(encoding)
    end
  end

  it "keeps unexpected dependency failures diagnostic without exposing their message" do
    error = ArgumentError.new("private retained source text")
    allow(Readability::Document).to receive(:new).and_raise(error)

    result = Nous::ExtractHtml.call(html: fixture("index.html"), source_url: "saved")

    expect(result.error).to be_a(Nous::ExtractHtml::UnexpectedFailure)
    expect(result.error.message).not_to include("private retained source text")
    expect(result.error.cause).to equal(error)
  end

  it "rejects empty final conversion output" do
    allow(ReverseMarkdown).to receive(:convert).and_return("")
    result = Nous::ExtractHtml.call(html: fixture("index.html"), source_url: "saved")
    expect(result.error).to be_a(Nous::ExtractHtml::NoContent)
  end

  it "counts title bytes in the exact output budget" do
    html = "<html><head><title>É</title></head><body><p>Café.</p></body></html>"
    exact = Nous::ExtractHtml.call(html: html, source_url: "saved", format: :text, max_output_bytes: 8)
    smaller = Nous::ExtractHtml.call(html: html, source_url: "saved", format: :text, max_output_bytes: 7)
    expect(exact).to be_success
    expect(exact.payload.title).to eq("É")
    expect(exact.payload.content).to eq("Café.")
    expect(smaller.error).to be_a(Nous::ExtractHtml::OutputLimitExceeded)
  end

  it "isolates concurrent retained originals and formats" do
    jobs = [[:text, "Alpha"], [:markdown, "Bravo"]]
    results = jobs.map do |format, name|
      Thread.new do
        Nous::ExtractHtml.call(html: "<html><head><title>#{name}</title></head><body><p>#{name} content.</p></body></html>",
          source_url: name, format: format)
      end
    end.map(&:value)
    expect(results.map { |result| result.payload.title }).to eq(["Alpha", "Bravo"])
    expect(results.map { |result| result.metadata[:format] }).to eq([:text, :markdown])
    expect(results.map { |result| result.metadata[:source_url] }).to eq(["Alpha", "Bravo"])
  end
end
