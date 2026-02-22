## [Unreleased]

- Remove `Nous::Error` base hierarchy; colocated errors inherit directly from `StandardError` with descriptive names
- Move extraction pipeline under `Nous::Fetcher::*` namespace (`ExtractionRunner`, `ExtractionThread`)
- Move readability command into `Nous::Extractor::Default::Client`, mirroring Jina structure
- `Nous::Extractor` is now a module namespace (implicit via Zeitwerk), no longer a Command
- Shared `Extractor::ExtractionError` contract: all extractor backends raise this on failure
- Pull `seed_url` off `Configuration`; `Crawler` owns URL parsing and validation directly
- Explicit rescue lists in CLI and extraction thread instead of broad `Nous::Error` rescue
- Rename `--verbose`/`-v` to `--debug`/`-d`; `-v` is now `--version`

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
