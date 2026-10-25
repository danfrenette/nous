# Defuddle runtime

Default URL and retained-HTML extraction requires Node.js 22 or newer on PATH.
The process adapter currently targets macOS/Linux (POSIX process groups). Install
Node explicitly using your normal runtime manager. No API key or service is used.
Check readiness from the repository root:

```bash
node --version
node -e 'if (Number(process.versions.node.split(".")[0]) < 22) process.exit(1)'
printf '%s' '{"html":"<html><head><title>Probe</title></head><body><p>Readable probe.</p></body></html>","url":"https://example.com"}' | node vendor/defuddle.mjs
```

Require exit zero and JSON containing title `Probe` and Markdown `Readable probe.`.
The published gem includes `vendor/defuddle.mjs` and third-party license notices;
users do not run npm. A missing Node binary produces an extraction failure.
`Nous.fetch(..., extractor: Nous::Extractor::Default.new)` and `--readability`
select the Ruby-only backup explicitly. Retained `ExtractHtml` requires Node.

## Rebuilding the bundled adapter

Maintainers use the pinned dependencies in `package-lock.json`. From the repository
root, provision dependencies explicitly and rebuild:

```bash
npm ci --ignore-scripts
npm run build
```

Commit the source, package manifest/lockfile, generated bundle and license notices
together. `javascript/build.mjs` regenerates the bundle and gathers dependency
license texts. Runtime extraction and verification never install dependencies.
Run the [Defuddle recipe](../verification/defuddle.md) after rebuilding.

The bridge uses a non-executing DOM parser, disables async extractors and rejects
fetch calls. It is not a browser renderer. The adapter uses a 15-second process
deadline and bounded output, but does not enforce a process memory limit. Callers
with stronger isolation requirements still own external process supervision.
