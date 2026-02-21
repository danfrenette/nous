# frozen_string_literal: true

require_relative "lib/nous/version"

Gem::Specification.new do |spec|
  spec.name = "nous"
  spec.version = Nous::VERSION
  spec.authors = ["Dan Frenette"]
  spec.email = ["dan.r.frenette@gmail.com"]

  spec.summary = "Crawl websites and extract readable markdown for LLM workflows"
  spec.description = "Nous crawls same-host web pages, extracts readable content, and serializes clean Markdown as text or JSON."
  spec.homepage = "https://github.com/danfrenette/nous"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/danfrenette/nous"
  spec.metadata["changelog_uri"] = "https://github.com/danfrenette/nous/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "async", "~> 2.24"
  spec.add_dependency "async-http", "~> 0.88"
  spec.add_dependency "faraday", "~> 2.12"
  spec.add_dependency "faraday-retry", "~> 2.2"
  spec.add_dependency "nokogiri", "~> 1.16"
  spec.add_dependency "reverse_markdown", "~> 3.0"
  spec.add_dependency "ruby-readability", "~> 0.7"
  spec.add_dependency "zeitwerk", "~> 2.6"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "standard", "~> 1.42"
  spec.add_development_dependency "webmock", "~> 3.25"
end
