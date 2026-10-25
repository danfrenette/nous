# Nous

Crawl websites and extract readable Markdown, optimized for LLM consumption. Inspired by [sitefetch](https://github.com/egoist/sitefetch).

Nous fetches same-host pages starting from a seed URL, extracts readable content, and outputs clean Markdown as XML-tagged text or JSON. It supports concurrent crawling, glob-based URL filtering, and local extraction with Defuddle by default and an explicit ruby-readability backup. Both parse acquired HTML without rendering JavaScript.

## Installation

Default extraction requires Node.js 22+ on PATH (macOS/Linux). The gem includes
the bundled Defuddle adapter; npm is only needed to rebuild it during development.
See [Defuddle setup](docs/setup/defuddle.md).

Add to your Gemfile:

```ruby
gem "nous"
```

Or install directly:

```bash
gem install nous
```

## CLI Usage

```bash
# Crawl a site and print extracted content to stdout
nous https://example.com

# Output as JSON
nous https://example.com -f json

# Write to a file
nous https://example.com -o site.md

# Limit pages and increase concurrency
nous https://example.com -l 20 -c 5

# Only crawl pages matching a glob pattern
nous https://example.com -m "/blog/*"

# Scope extraction to a CSS selector
nous https://example.com -s "article.post"

# Use the Ruby-only Readability backup
nous https://example.com --readability

# Debug logging
nous https://example.com -d
```

### Options

| Flag | Description | Default |
|------|-------------|---------|
| `-o`, `--output PATH` | Write output to file | stdout |
| `-f`, `--format FORMAT` | Output format: `text` or `json` | `text` |
| `-c`, `--concurrency N` | Concurrent requests | `3` |
| `-m`, `--match PATTERN` | Glob filter for URLs (repeatable) | none |
| `-s`, `--selector SELECTOR` | CSS selector to scope extraction | none |
| `-l`, `--limit N` | Maximum pages to fetch | `100` |
| `--timeout N` | Per-request timeout in seconds | `15` |
| `--readability` | Use the Ruby-only Readability backup | off |
| `-v`, `--version` | Print version and exit | off |
| `-h`, `--help` | Print usage and exit | off |
| `-d`, `--debug` | Debug logging to stderr | off |

## Ruby API

### Basic Usage

```ruby
require "nous"

# Fetch pages with the default extractor
pages = Nous.fetch("https://example.com", limit: 10, concurrency: 3)

# Each page is a Nous::Page with title, url, pathname, content, metadata
pages.each do |page|
  puts "#{page.title} (#{page.url})"
  puts page.content
end

# Serialize to XML-tagged text
text = Nous.serialize(pages, format: :text)

# Serialize to JSON
json = Nous.serialize(pages, format: :json)

# Select the Readability backup explicitly
pages = Nous.fetch("https://example.com",
  extractor: Nous::Extractor::Default.new,
  limit: 5
)
```

### Detailed Results

Use the `details: true` option to receive full fetch results including failures:

```ruby
result = Nous.fetch("https://example.com", details: true)

result.pages       # Array<Nous::Page> - successfully extracted pages
result.failures    # Array<{requested_url:, error:}> - failed acquisition or extraction
result.total_requested  # Integer - total URLs attempted
result.all_succeeded?   # Boolean - true if no failures
result.any_succeeded?   # Boolean - true if at least one page extracted
```

Acquisition failures retain their existing messages; extraction failures retain their
exception objects. Detailed results include failed recursive requests as well as
failed extraction. Pages-only calls still return successful pages in source order.
A concurrent batch may already have attempted more successful pages than the limit
allows returning. `total_requested` counts every attempted request in that batch;
failures remain visible, while excess successful pages are omitted from `pages`.
The limit still governs retained successful pages, not failed attempts.

This is useful when you need to handle failures explicitly:

```ruby
result = Nous.fetch("https://example.com/api-docs", details: true)

if result.failures.any?
  puts "Failed to fetch:"
  result.failures.each do |failure|
    puts "  #{failure[:requested_url]}: #{failure[:error]}"
  end
end

result.pages.each do |page|
  puts "Successfully extracted: #{page.title}"
end
```

### Retained HTML extraction

Use saved bytes directly, without crawling or reacquiring a URL:

```ruby
result = Nous::ExtractHtml.call(
  html: File.binread("saved.html"),
  source_url: "https://example.com/article",
  content_type: "text/html; charset=utf-8",
  format: :text
)
raise result.error if result.failure?
puts result.payload.title
puts result.payload.content
puts result.metadata
```

`html:` and `source_url:` are required. The URL is provenance only; this command
never requests it. `content_type:` defaults to `"text/html"`; HTML and XHTML are
supported. `format:` defaults to `:markdown`; `:text` returns readable text with
collapsed whitespace and separated blocks. Defuddle is used for both formats. Legacy `Extractor::Default#extract`
continues producing Markdown with its existing selector behavior.

Character decoding uses a declared content-type charset first, then a UTF BOM,
then an HTML meta charset in the first 1024 bytes, then UTF-8. Input is treated as
bytes regardless of its Ruby encoding label and is never modified. Invalid byte
sequences and decoded NULs fail; unsupported charset names fail explicitly. A
conflicting meta declaration does not override a declared header charset.

The result payload remains `Nous::ExtractedContent` (`title`, `content`). Metadata
contains `source_url`, original `content_type`, selected `encoding`, `format`, and
limitations `static_html_only` and `authentication_not_detected`. Static readable
content does not prove that an authenticated or JavaScript-rendered page is complete.

`max_input_bytes:` defaults to 25 MiB; `max_output_bytes:` defaults to 32 MiB.
Both require positive integers. Input is checked before copying/parsing. Output
counts the combined UTF-8 bytes of title and content, excluding caller-supplied
provenance metadata. These are input/result guards, not peak-memory, CPU or wall-time
limits; callers needing those protections must retain process supervision.

Expected errors are nested under `Nous::ExtractHtml`:

| Error | Meaning |
| --- | --- |
| `InvalidContent` | Invalid encoded bytes, NULs, or invalid decoded output |
| `UnsupportedContent` | Unsupported media type, output format or charset |
| `NoContent` | No readable content or empty converted output |
| `InputLimitExceeded` / `OutputLimitExceeded` | Caller byte budget exceeded |
| `InvalidLimits` (`ArgumentError`) | Nonpositive or noninteger byte limit |
| `UnexpectedFailure` | Safe outward message; original exception in `cause` |

Treat diagnostic causes as private debugging data; their messages can contain
source content. Rails acquisition, storage, lifecycle and process supervision are
outside this command. See the [verification map](docs/verification/README.md) for
executed surfaces and remaining consumer acceptance.

### Page Structure

Each extracted page contains:

| Field | Type | Description |
|-------|------|-------------|
| `title` | String | Page title selected by the extraction backend |
| `url` | String | Final URL after redirects |
| `pathname` | String | URL path component |
| `content` | String | Extracted content as Markdown |
| `metadata` | Hash | Provenance information (see below) |

### Page Metadata

```ruby
page.metadata  # => {
  #   extractor: "Nous::Extractor::Defuddle",  # Which extractor was used
  #   requested_url: "https://example.com/blog", # Original URL before redirects
  #   content_type: "text/html; charset=utf-8",  # HTTP Content-Type header
  #   redirected: true                           # Whether redirects occurred
  # }
```

## Extraction Backends

### Defuddle (default)

Runs the bundled Defuddle parser in Node.js against the acquired HTML and final
URL. Returns Markdown directly, retaining structure such as code blocks, tables,
and links. Supports `--selector`. Each extraction owns its process, with a
15-second deadline, a 64 MiB JSON response limit and a 64 KiB diagnostic limit.
These are separate from HTTP timeouts and retained-command byte budgets.
Page scripts do not execute and third-party fallback fetching is disabled.
Failures remain visible through `details: true`; there is no automatic switch
to Readability. `ExtractHtml` uses this same engine while retaining its decoding,
plain-text rendering and byte-budget contract.

### Readability (explicit backup)

Parses static HTML using [ruby-readability](https://github.com/cantino/ruby-readability), strips noisy elements (script, style, nav, footer), and converts to Markdown via [reverse_markdown](https://github.com/xijo/reverse_markdown). Fast and requires no external services, but cannot extract content from JS-rendered pages.

Title extraction uses a fallback chain:
1. Readability's extracted title
2. Original `<title>` tag from HTML
3. First `<h1>` from extracted content

### Migrating from Jina

`Extractor::Jina` and `--jina` have been removed. Remove the extractor argument or
flag to use Defuddle; `JINA_API_KEY` is no longer used. This retires remote browser
rendering: pages requiring JavaScript may yield incomplete or no readable content.
Use `Extractor::Default.new` or `--readability` for the Ruby-only backup.
`ExtractHtml` always uses Defuddle; its result and error shapes remain unchanged.

## Output Formats

### Text (default)

XML-tagged output designed for LLM context windows:

```xml
<page>
  <title>Page Title</title>
  <url>https://example.com/page</url>
  <pathname>/page</pathname>
  <extractor>Nous::Extractor::Defuddle</extractor>
  <content>
# Heading

Extracted markdown content...
  </content>
</page>
```

### JSON

```json
[
  {
    "title": "Page Title",
    "url": "https://example.com/page",
    "pathname": "/page",
    "content": "# Heading\n\nExtracted markdown content...",
    "metadata": {
      "extractor": "Nous::Extractor::Defuddle",
      "requested_url": "https://example.com/page",
      "content_type": "text/html; charset=utf-8",
      "redirected": false
    }
  }
]
```

## Development

Read [CODING_STANDARDS.md](CODING_STANDARDS.md) before implementation and include it
in Anaphor Standards reviews. Use the [verification map](docs/verification/README.md)
and project-local [verify-nous skill](.agents/skills/verify-nous/SKILL.md) for the
retained-HTML and failure-propagation readiness checks.

```bash
bin/setup               # Install dependencies
bundle exec rspec       # Run tests
bundle exec standardrb  # Lint
bundle exec exe/nous    # Run the command line in-development
```

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
