# frozen_string_literal: true

require "tmpdir"
require "rubygems/package"
require "open3"
require "rbconfig"

RSpec.describe "Packaged Defuddle runtime readiness" do
  it "extracts outside the checkout without node_modules or Jina" do
    root = File.expand_path("../..", __dir__)
    Dir.mktmpdir("nous-package-") do |directory|
      gem_path = File.join(directory, "nous.gem")
      unpacked = File.join(directory, "unpacked")
      Dir.chdir(root) do
        Gem::Package.build(Gem::Specification.load("nous.gemspec"), false, false, gem_path)
      end
      Gem::Package.new(gem_path).extract_files(unpacked)
      code = <<~RUBY
        require "nous"
        path = $LOADED_FEATURES.find { |file| file.end_with?("/lib/nous.rb") }
        abort "Wrong Nous installation" unless File.realpath(path) == File.realpath(#{File.join(unpacked, "lib/nous.rb").inspect})
        abort "Jina still packaged" if defined?(Nous::Extractor::Jina)
        result = Nous::ExtractHtml.call(
          html: "<html><head><title>Packaged</title></head><body><p>Bundled content.</p></body></html>",
          source_url: "https://example.com")
        raise result.error if result.failure?
        abort "Wrong title" unless result.payload.title == "Packaged"
        abort "Wrong content" unless result.payload.content == "Bundled content."
        puts "Packaged Defuddle extraction passed"
      RUBY
      stdout, stderr, status = Open3.capture3({"RUBYOPT" => nil, "BUNDLE_GEMFILE" => nil},
        RbConfig.ruby, "-I#{unpacked}/lib", "-e", code, chdir: directory)
      expect(status.success?).to be(true), stderr
      expect(stdout).to include("Packaged Defuddle extraction passed")
    end
  end
end
