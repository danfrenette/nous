# Defuddle extraction

Status: implemented; execute on the source under review.

Outcomes: Defuddle is the default for `Nous.fetch`, `Fetcher` and `ExtractHtml`.
The CLI selects Defuddle unless `--readability` is supplied. Jina is removed.
The extractor consumes already acquired HTML and the final URL, returns title
and Markdown through the existing result contract, honors selectors, resolves
relative links, and keeps concurrent calls isolated. Empty content and runtime
failures remain failures; no automatic Readability fallback occurs.

Follow [launch and doctor](README.md) and [Node readiness](../setup/defuddle.md).
Then run:

```bash
BUNDLE_FROZEN=true bundle exec rake verify:defuddle > "$receipt_dir/defuddle.log" 2>&1
printf '%s\n' "$?" > "$receipt_dir/defuddle.exit"
```

Require exit zero. The extractor specs exercise the actual bundled parser with
synthetic HTML. Client specs cover JSON/field validation, empty content and propagation of a
failed process result. `RunProcess` specs independently exercise raw process
output, nonzero exit, output limits, reaping and timeout cleanup with controlled
Ruby subprocesses. Missing-runtime and safe-diagnostic errors are covered through `RunProcess`. CLI specs check backend selection and observable selector behavior. Acquired-byte
specs cover BOM/meta decoding and meaningful invalid-byte/charset failures.
Run the retained-HTML and failure-propagation recipes, full suite and Standard too.

For installed-runtime and packaging compatibility, run the separate opt-in check:

```bash
BUNDLE_FROZEN=true bundle exec rake verify:defuddle_package > "$receipt_dir/defuddle-package.log" 2>&1
printf '%s\n' "$?" > "$receipt_dir/defuddle-package.exit"
```

Require exit zero. The harness in `spec/verification/defuddle_package.rb` builds
and unpacks the gem in an isolated temporary directory, verifies the loaded Nous
path, checks Jina is absent, and asserts title/content through `ExtractHtml`.
It owns and cleans up the temporary package on success and failure. This verifies
that extraction does not resolve npm dependencies from the checkout.

Record source identity, commands, exit statuses and logs using the verification
guide. Runtime checks establish compatibility only with the Node/platform tested;
controlled subprocesses do not establish Node compatibility. Synthetic fixtures
do not establish extraction quality across live sites, JavaScript completeness,
authentication detection or downstream Substrate acceptance.
