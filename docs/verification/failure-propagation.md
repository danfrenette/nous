# Visible extraction failures

Status: implemented; run this recipe on the target revision before claiming verification.
This is the accepted readiness requirement, with pages-only compatibility preserved.

**Outcome FP-1:** A caller invokes `Nous.fetch(..., details: true)` after successful
acquisition of unreadable HTML. The detailed result retains a visible failure for
that original and must not report `all_succeeded?`. An empty successful page list
alone is insufficient for Substrate/Autodidact's explicit-outcome handoff.

**Entry point:** Public `Nous.fetch`, single-page mode (`limit: 1`), detailed results.
Default pages-only behavior and legacy runner specs are not changed by this recipe.

**Prerequisites:** Follow [launch and doctor](README.md). The opt-in harness at
`spec/verification/failure_propagation.rb` stubs one HTTP response with WebMock;
all real network is disabled. It exercises real crawling, parsing and collection.
No account or persistent record is created.

**Drive:**

```bash
BUNDLE_FROZEN=true bundle exec rake verify:failure_propagation > "$receipt_dir/failure-propagation.log" 2>&1
printf '%s\n' "$?" > "$receipt_dir/failure-propagation.exit"
```

**Assertions:** Failed original URL remains visible in `failures`; `all_succeeded?`
is false and no page is fabricated. Require exit zero. The ordinary integration suite also covers mixed acquisition and
extraction failures, readable page order, and original unexpected extractor errors.

**Evidence and cleanup:** Follow [capture and cleanup](README.md). Retain the failed
log and exit status. WebMock and Nous configuration reset with the test process.
This focused check alone does not prove stable error categories,
unexpected diagnostic causes, resource exhaustion or consumer integration.
