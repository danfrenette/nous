# Retained HTML

Status: implemented; execute on the target source before claiming verification.

**Outcomes:** RH-1 accepts retained HTML bytes through `Nous::ExtractHtml.call`
without network or input mutation, returning readable content, title and source
metadata. RH-2 selects `:text` or default `:markdown`. RH-3 applies header charset,
then BOM, then meta in the first 1024 bytes, then UTF-8, rejecting invalid bytes,
NULs and unsupported requests. RH-4 enforces positive input and combined title/content
UTF-8 output budgets. RH-5 separates expected failures from safe unexpected failures
with diagnostic causes; concurrent calls retain their own content and metadata.
Legacy `Extractor::Default#extract` remains compatible.

**Prerequisites:** Follow [launch and doctor](README.md). The synthetic existing
fixtures and inline examples contain no private captures. No identity or durable
state is involved. WebMock disables network. External readability/Markdown failures
are controlled only in diagnostic and empty-conversion tests.

**Drive:**

```bash
BUNDLE_FROZEN=true bundle exec rake verify:retained_html > "$receipt_dir/retained-html.log" 2>&1
printf '%s\n' "$?" > "$receipt_dir/retained-html.exit"
```

**Assertions:** Require exit zero. The task runs public retained-command tests and
legacy default extractor tests. They check title/content, selector compatibility,
unreadable failure, header/meta conflict, BOM/meta/default charset, invalid bytes,
NULs, formats/types, real charset declarations versus examples, byte thresholds, title-inclusive multibyte budgets, safe
unexpected causes, empty final conversion and concurrent isolation. See
[the public contract](../../README.md#retained-html-extraction) for supported policy.
There is no durable application write to read back.

**Evidence and cleanup:** Follow [capture and cleanup](README.md). Preserve log,
exit status and source identity. This proves synthetic local parser behavior,
not all real-world document quality, JavaScript rendering, authentication detection,
process CPU/memory/wall-time limits or Substrate/Autodidact/hosted compatibility.
