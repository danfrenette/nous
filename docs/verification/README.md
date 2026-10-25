# Nous verification

The project-local [verify-nous skill](../../.agents/skills/verify-nous/SKILL.md)
uses this guide. Initial scope is the two selected architecture candidates:
retained-HTML extraction and visible extraction failures. This map does not
certify all crawling, rendering, serialization or consumer behavior.

| Recipe | State | Coverage |
| --- | --- | --- |
| [Retained HTML](retained-html.md) | Implemented; run required | Offline content/provenance, formats, decoding, byte budgets, errors and legacy compatibility |
| [Failure propagation](failure-propagation.md) | Implemented; run required | Public detailed result must retain extraction failure |

## Launch

Follow [setup](../setup/verification.md). These are one-shot Ruby commands; no
persistent process is launched. Start an evidence directory for this run:

```bash
mkdir -p tmp/verification
receipt_dir="$(mktemp -d "$PWD/tmp/verification/run-XXXXXX")"
export receipt_dir
```

Keep the same shell variable for the commands below. Do not pipe through `tee`
without preserving the original exit status.

## Doctor

```bash
ruby -v > "$receipt_dir/ruby.log" 2>&1
printf '%s\n' "$?" > "$receipt_dir/ruby.exit"
BUNDLE_FROZEN=true bundle check > "$receipt_dir/bundle.log" 2>&1
printf '%s\n' "$?" > "$receipt_dir/bundle.exit"
git rev-parse HEAD > "$receipt_dir/head.txt"
git status --short > "$receipt_dir/status.txt"
git diff --binary HEAD > "$receipt_dir/working-tree.patch"
BUNDLE_FROZEN=true bundle exec ruby -Ilib -r nous -e 'puts Nous::VERSION; puts $LOADED_FEATURES.grep(%r{/lib/nous.rb$})' > "$receipt_dir/target.log" 2>&1
printf '%s\n' "$?" > "$receipt_dir/target.exit"
git ls-files --others --exclude-standard -z | BUNDLE_FROZEN=true bundle exec ruby -rdigest -e 'STDIN.read.split("\0").each { |path| puts "#{Digest::SHA256.file(path).hexdigest}  #{path}" if File.file?(path) }' > "$receipt_dir/untracked.sha256"
```

Inspect each exit file and the target path before driving: Ruby, bundle and target
must exit zero and target must resolve this checkout. Untracked hashes identify
new recipes/harnesses; retain their contents with the change. For committed work,
HEAD identifies the source; for dirty work retain the patch and hashes too.

## Drive and capture

Discover opt-in checks with `bundle exec rake -T`.
Run each selected recipe's exact command, redirect its output to the named log,
and immediately record `$?` in its exit file. A nonzero product assertion stays
failed; do not weaken it to current behavior. For a prerequisite failure, attempt
one documented setup recovery, retry once, then mark blocked if unavailable.

Record a receipt table with criterion, repository/revision, command, expected,
observed, evidence path and pass/fail/blocked/not-run status. Keep failed logs.
Do not treat successful neighbors as readiness for a failed or unimplemented goal.

For Ruby or harness changes also run `BUNDLE_FROZEN=true bundle exec rspec` and
`BUNDLE_FROZEN=true bundle exec standardrb`, capturing output and exit status.
The draft readiness harness is opt-in and is not part of ordinary specs.

## Cleanup

These checks leave no server, child process, storage record or fixture changes.
RSpec may update the ignored `.rspec_status`; it is not evidence. Keep
`$receipt_dir` and all logs after cleanup; do not delete the evidence directory.
Never use private captures for the synthetic fixture checks.

## Coverage limits

Real-world readability quality, process CPU/memory/wall-time supervision,
Substrate integration, locked Autodidact compatibility and hosted acceptance remain
outside this map. Jina reacquires URLs and is outside retained-original verification.
The caller owns immutable storage and any application lifecycle. Passing library
recipes alone does not certify downstream adoption.
