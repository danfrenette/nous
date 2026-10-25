# Verification setup

Work from the Nous repository root. Use the Ruby declared in `.ruby-version`
(currently 4.0.1), the Bundler version in `Gemfile.lock` (currently 4.0.6), and
that lockfile's gems. With rbenv, `rbenv exec ruby -v` must identify the intended
Ruby; shell/system Ruby 2.6 is unsuitable. Put rbenv shims on PATH or prefix the
commands in the verification guide with `rbenv exec`.

Run `BUNDLE_FROZEN=true bundle check`. If dependencies are absent, run
`BUNDLE_FROZEN=true bundle install` once, then repeat the check. Installation may
need network and permission to write the gem installation. If Ruby/Bundler is
missing, provision those declared versions using your runtime manager first.
Do not update or regenerate the lockfile to make verification work. Frozen mode
also prevents Bundler from opportunistically rewriting platform metadata.

The recipes use RSpec, WebMock and Nous's locked parsing dependencies. No server,
Jina key, browser, remote account, external binary or model is needed. HTTP in the
failure recipe is a controlled response fixture; all other network is disabled.
No credentials or retained private content belong in evidence.
