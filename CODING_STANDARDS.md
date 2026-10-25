# Coding standards

Read these standards before implementation and include them in Anaphor's Standards
review. They apply to this Ruby gem and its development tools. Existing code is not
a blanket exception: when changing an affected boundary, address deviations or
record a concrete compatibility reason in the PR. This document does not itself
change existing public APIs.

## Responsibilities and service objects

Keep crawling, readable-content extraction, conversion, and serialization distinct.
Commands perform operations; fetch records describe acquired originals; pages describe
extracted content and provenance. Keep HTTP details in crawler and remote extractor
adapters. Follow the existing Zeitwerk layout; `lib/nous/primitives/` is collapsed
into the `Nous` namespace.

A command exposes one public instance operation, `call`, invoked through inherited
`.call`. Its initializer accepts explicit inputs and dependencies and stores state;
construction must not launch processes, perform network requests, or do business
work. Resolve environment-dependent defaults when the operation runs.

Application-service instance `call` methods that describe business operations must
contain only bareword calls to private methods named for business functions. Read
them as prose: one named step per line, without arguments, explicit receivers,
assignments, conditionals, loops, blocks, or explicit returns. A `rescue` clause
is the only exception; it may map an expected exception to a failure result.
Put decisions, resource scopes, collaborator calls, and result construction inside
the private steps. The final step returns the service result. For example:

```ruby
def call
  prepare_retained_content
  extract_readable_content
  build_extraction_result
rescue ArgumentError => error
  failure(error)
end
```

A failed prerequisite must stop the sequence: raise a meaningful exception handled
by the service or the existing command boundary. Returning a failure from a private
step alone does not stop later steps. Keep resource acquisition, use and cleanup
in one private scope rather than spreading temporary paths across orchestration
steps. Do not add instance state merely to split an indivisible operation.

This rule governs business-operation services, including extraction workflows. The shared class-level dispatcher and low-level value/protocol helpers
are not business orchestration. Apply the rule when changing an existing service;
this change does not claim that all historical commands have been migrated.

Before extracting an object, name the policy, resource, or collaborator contract
it will own. If no separate owner exists, keep the steps private in the current
service. Do not extract forwarding layers to satisfy a line count: they add places
to navigate without reducing the caller's obligations. Name an extraction for its
operation, not Manager, Processor, or Utils. Keep duplication when sharing would
require unrelated behavior flags; those flags couple operations that change apart.

Use Sandi Metz's five-line methods, 100-line classes, and four-parameter guideline
as review prompts, not mechanical limits. Count independent keyword options as
parameters. A growing constructor suggests mixed responsibilities; hiding those
options in a hash does not fix that. Introduce an input object only when its data
has cohesive behavior or invariants. Explain justified exceptions locally in the PR.

Apply tell, don't ask: put an operation with the object that owns its behavior.
Use a known collaborator's interface instead of branching on `is_a?`, `kind_of?`,
or `respond_to?`. At an untrusted provider boundary, validate the actual protocol
and required data before producing normalized content. Do not spread speculative
type checks through in-process callers.

## Arguments and defaults

For each proposed argument, inspect its callers and choose in this order:

1. If no caller or accepted use case needs the choice, do not add the argument.
   A test convenience alone does not justify expanding the public API.
2. If every caller must supply a value, require it.
3. If omission selects a normal value, give it a concrete default or default
   expression. Do not use `nil` merely to replace it with that value later.
4. If absence changes the operation, document it and permit `nil`. For example,
   `selector: nil` leaves extraction unscoped.
5. If automatic selection differs from an explicit override, represent that mode
   explicitly and test both paths. Discover environment dependencies during `call`,
   not construction, so creating the service does not launch work.

For an existing argument, record the behavior of omission, explicit `nil`, and
explicit values before editing. Preserve supported cases and test the changed
boundary. Do not silently make a strict executable override fall back to another
installation. Add a sentinel or null object only when those behaviors must differ;
otherwise it adds another state every caller must understand.

## Results, failures, and resources

Use the existing `Nous::Command` and `Nous::Command::Result` contract in
[lib/nous/command.rb](lib/nous/command.rb): commands return `payload`, `error`, and
`metadata`; callers inspect `success?` or `failure?`. Extractors expose `extract(record)`
and return the same result contract; do not rename that protocol as a style change. Do not copy Rails `ApplicationService`, named
result fields, HTTP error codes, or reporting infrastructure into this gem.

The inherited class `.call` currently converts `StandardError` into a failure
result, wrapping post-construction errors as `CommandError`. Preserve that behavior
unless an explicit API change is accepted. Direct instance `call` and extractor
`extract` do not receive that dispatcher protection. A failed child command does not
short-circuit its parent automatically: inspect its result and stop before any
step that depends on success. Keep stage-specific errors useful without including
credentials or sensitive source content. Do not turn a failure into empty success.

One owner acquires, uses, and releases each temporary resource. Keep cleanup in a
block or `ensure` that covers success and failure, including parsing. Do not return
a temporary path after its owner has released it. Never use the original input as
an output destination. Invoke subprocesses with argument arrays, not interpolated
shell strings. Make partial external effects explicit; cleanup cannot undo them all.

## Development and verification commands

Choose the command's owner before adding a file:

1. For a repeatable project check, add a named Rake task. Put live checks under
   `verify:` and document inputs in the owning recipe so agents can discover them
   with `bundle exec rake -T`. Create these directories when a check needs them.
2. Put verification assertions, fixture preparation, and cleanup in a focused
   harness under `spec/verification/`. Keep `tasks/*.rake` limited to task inputs
   and dispatch, so command plumbing does not obscure what the check proves.
3. Use `bin/` for setup and console; the existing public command lives in `exe/nous`. Do not
   add a generic scripts directory for verification commands; it creates a second
   entry-point convention to discover and maintain.

Keep production behavior in the library and exercise its public API from the
harness. Never add downloads or live provider calls to default `bundle exec rake`;
ordinary verification must run without external services or model provisioning.

Document required binaries, models, credentials, supported runtime versions, and
readiness checks in `docs/setup/`. Keep executable verification steps and evidence
limits in `docs/verification/`. Link both from onboarding. Install dependencies through explicit setup
steps, never silently during a check; readiness and behavior verification are separate results. Retain evidence with
the tested source revision; never claim that simulated processes prove a local
runtime works.

## Tests and review

Test observable outcomes through command `.call` or the owning source interface.
Do not assert private helper order. When a workflow has prerequisites, cover failure before dependent steps. When it
owns files or processes, cover cleanup and input preservation on success and
failure. When calls can overlap, prove their resources stay isolated. Use
controlled provider/process fixtures for ordinary tests and separate opt-in live
checks for actual compatibility. Keep fixtures' provenance and limitations visible.

For Ruby changes, run affected specs, the full RSpec suite, and Standard using
the Development commands in [README.md](README.md). Include an affected verification
recipe once one exists. Documentation-only changes need
link, command, and contract checks; they do not require pretending runtime behavior
changed. Anaphor reviews must distinguish documented rules, design heuristics, and
accepted requirements. A green suite does not establish compliance with every
principle or prove live-provider behavior.

## Retained HTML convention

`ExtractHtml` keeps six explicit inputs: original bytes, source URL, content type,
output representation and two independent caller budgets. This is a deliberate
exception to the parameter heuristic: a hash or options object without cohesive
behavior would only hide the same choices. The command owns decoding, readable
selection, rendering and bounded output together. Legacy shared extractors must
not acquire per-record mutable state: the fetch runner calls them concurrently.

## Sources and adaptation

Adapted from Substrate's `CODING_STANDARDS.md` on October 25, 2026, which was
adapted from Autodidact's standards. Nous-specific responsibilities, result names,
extractor protocol, executable locations, and verification commands replace their
Substrate equivalents. Local audio conventions do not apply to Nous.
Retained service orchestration, explicit inputs, failure sequencing, ownership,
and public-interface testing. Rails controllers, Active Record, transactions,
Jbuilder, Sentry, Next.js, and that application's result shape are outside this
project's conventions. The source document provides context, not inherited
instructions to provision those systems.

- [Thoughtbot: Tell, Don't Ask](https://thoughtbot.com/blog/tell-dont-ask)
  informs behavior ownership and collaborator interfaces.
- [Thoughtbot: Sandi Metz' Rules for Developers](https://thoughtbot.com/blog/sandi-metz-rules-for-developers)
  supplies the size and parameter heuristics; their use as review prompts here is
  a local convention.
- [Sandi Metz: The Wrong Abstraction](https://sandimetz.com/blog/2016/1/20/the-wrong-abstraction)
  informs the preference for cohesive objects over premature generalization.

Nullable-default policy and Rake placement are project decisions, not rules
attributed to these authors.
