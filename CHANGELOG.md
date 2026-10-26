## [0.5.0] - 2026-10-25

### Added

- `Nous::ExtractHtml.call` extracts retained HTML without network acquisition, with
  Markdown or plain text, source metadata, explicit decoding errors and caller byte limits.

### Changed

- Defuddle is the default for URL and retained-HTML extraction. The gem bundles
  its JavaScript dependencies and requires Node.js 22+ on macOS/Linux.
- Readability remains available through `Extractor::Default` and `--readability`.
  Extraction failures do not silently switch backends.

### Removed

- Jina Reader integration (`Extractor::Jina`, `--jina`, `JINA_API_KEY`). Neither
  remaining backend renders JavaScript pages.

### Fixed

- Detailed fetch results retain extraction failures and all attempted failures from
  concurrent crawl batches, with accurate request counts and unchanged page limits.

## [0.4.0] - 2026-04-11

### Added

- **New `details: true` option for `Nous.fetch`** - Returns a `FetchResult` object containing both successful pages and failed fetch/extraction attempts. This enables explicit failure handling without exceptions.
  ```ruby
  result = Nous.fetch("https://example.com", details: true)
  result.pages    # Array<Page> - successfully extracted
  result.failures # [{requested_url:, error:}, ...]
  ```

- **Page metadata** - Every extracted page now includes provenance information:
  - `extractor`: Which extractor backend was used (e.g., "Nous::Extractor::Default")
  - `requested_url`: The original URL before any redirects
  - `content_type`: HTTP Content-Type header from the response
  - `redirected`: Boolean indicating if redirects occurred

- **FetchRecord internal primitive** - Unified fetch result representation that captures both success and failure cases with full provenance tracking. Replaces the previous `RawPage` which only handled successful fetches.

- **Configuration#single_page? helper** - Convenience predicate method for checking if the current configuration is in single-page (non-recursive) mode.

### Changed

- **Improved title extraction** - Title extraction now uses a fallback chain: readability extracted title → HTML `<title>` tag → first `<h1>` element. This significantly improves title reliability on pages where readability fails to identify the title.

- **Reduced aggressive DOM stripping** - The default extractor now preserves more content before readability processing. Previously removed elements (`header`, `img`, `video`, `svg`, `link`) are now retained, providing better context for readability scoring and preserving useful content like captions and bylines.

- **Unified fetch contract** - Both single-page and recursive crawling now use the same internal `FetchRecord` structure, ensuring consistent provenance tracking and failure handling across all fetch modes.

- **Serializer schema updated** - Both text and JSON output formats now include:
  - `pathname`: URL path component
  - `extractor`: Which extractor processed the page
  - Full metadata object (JSON only)

### Fixed

- **JSON serialization** - The JSON output now correctly includes the `pathname` field that was documented but missing in previous versions.

- **Extraction failure visibility** - Previously, extraction failures were only visible with debug logging enabled. The new `FetchResult` structure makes failures programmatically accessible.

### Internal Changes

- **Duck-typed extractor interface** - Extractors now receive the full `FetchRecord` object and can access the fields they need (`Default` uses `record.html`, `Jina` uses `record.final_url`).

- **Removed `RawPage` primitive** - Superseded by the richer `FetchRecord` which handles both success and failure uniformly.

## [0.3.0] - 2026-02-23

- Remove `Nous::Error` base hierarchy; colocated errors inherit directly from `StandardError` with descriptive names
- Move extraction pipeline under `Nous::Fetcher::*` namespace (`ExtractionRunner`, `ExtractionThread`)
- Move readability command into `Nous::Extractor::Default::Client`, mirroring Jina structure
- `Nous::Extractor` is now a module namespace (implicit via Zeitwerk), no longer a Command
- Shared `Extractor::ExtractionError` contract: all extractor backends raise this on failure
- Pull `seed_url` off `Configuration`; `Crawler` owns URL parsing and validation directly
- Explicit rescue lists in CLI and extraction thread instead of broad `Nous::Error` rescue
- Rename `--verbose`/`-v` to `--debug`/`-d`; `-v` is now `--version`
- Add `Nous::Url`, `Nous::UrlResolver`, and `Crawler::RedirectFollower` to correctly handle redirects and path encoding (including spaces)
- Add `-r`/`--recursive`; default mode now fetches only the seed page unless recursion is explicitly enabled
- Split crawler fetchers by mode: `Crawler::AsyncPageFetcher`, `Crawler::RecursivePageFetcher`, and `Crawler::SinglePageFetcher`
- Move configuration construction to `ConfigurationBuilder` and `Data.define`-based `Configuration` primitive
- Add `faraday-follow_redirects` for single-page redirect handling and update integration/spec coverage for recursive and single-page flows

## [0.2.0] - 2026-02-21

- Promote Configuration to module-level singleton (`Nous.configure`, `Nous.configuration`)
- Eliminate verbose/concurrency/timeout parameter drilling through pipeline classes
- Promote ExtractionRunner to Command pattern
- Suppress async-pool gardener ThreadError in non-verbose mode
- Add CLI specs and full pipeline integration test
- Replace boilerplate README with real documentation
- Upgrade to Ruby 4.0.1

## [0.1.0] - 2026-02-21

- Initial release

[Unreleased]: https://github.com/danfrenette/nous/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/danfrenette/nous/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/danfrenette/nous/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/danfrenette/nous/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/danfrenette/nous/releases/tag/v0.1.0
