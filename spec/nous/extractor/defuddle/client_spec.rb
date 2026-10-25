# frozen_string_literal: true

require "rbconfig"

RSpec.describe Nous::Extractor::Defuddle::Client do
  def extract
    described_class.call(html: "<html><body><p>Private content.</p></body></html>", url: "https://example.com")
  end

  def process_fixture(code)
    allow(Open3).to receive(:popen3).and_wrap_original do |original, *args, **options, &block|
      original.call(RbConfig.ruby, "-e", code, **options, &block)
    end
  end

  it "reports a missing runtime without downloading or switching extractors" do
    allow(Open3).to receive(:popen3).and_raise(Errno::ENOENT)
    result = extract
    expect(result).to be_failure
    expect(result.error.message).to include("Node.js")
  end

  it "rejects process failures without exposing stderr" do
    process_fixture('STDIN.read; STDERR.write("private source"); exit 1')
    result = extract
    expect(result).to be_failure
    expect(result.error.message).to eq("Defuddle extraction failed")
  end

  it "rejects malformed JSON and invalid response fields" do
    ["not-json", '{"title":4,"content":"body","markdown":"body"}', '{"title":"title","content":"body","markdown":"bad\\u0000text"}'].each do |output|
      process_fixture("STDIN.read; STDOUT.write(#{output.dump})")
      expect(extract.error).to be_a(described_class::ProcessError)
    end
  end

  it "does not expose invalid input bytes in error messages" do
    result = described_class.call(html: "private\xFF".b, url: "https://example.com")
    expect(result).to be_failure
    expect(result.error.message).not_to include("private")
  end

  it "does not turn an empty extraction into success" do
    process_fixture('STDIN.read; puts %q({"title":"Title","content":"","markdown":" "})')
    expect(extract.error).to be_a(described_class::NoContent)
  end

  it "bounds process output" do
    stub_const("#{described_class}::OUTPUT_LIMIT", 1024)
    process_fixture('STDIN.read; loop { STDOUT.write("x" * 2048); STDOUT.flush }')
    expect(extract.error.message).to include("byte limit")
  end

  it "reaps the process after success, nonzero exit and invalid JSON" do
    ['STDIN.read; puts %q({"title":"Title","content":"<p>Body</p>","markdown":"Body"})',
      "STDIN.read; exit 1", 'STDIN.read; puts "invalid"'].each_with_index do |code, index|
      pid = nil
      allow(Open3).to receive(:popen3).and_wrap_original do |original, *args, **options, &block|
        original.call(RbConfig.ruby, "-e", code, **options) do |*pipes|
          pid = pipes.last.pid
          block.call(*pipes)
        end
      end
      result = extract
      expect(result.success?).to eq(index.zero?)
      expect { Process.waitpid(pid, Process::WNOHANG) }.to raise_error(Errno::ECHILD)
    end
  end

  it "terminates and reaps a timed-out process" do
    stub_const("#{described_class}::TIMEOUT", 0.2)
    pid = nil
    allow(Open3).to receive(:popen3).and_wrap_original do |original, *args, **options, &block|
      original.call(RbConfig.ruby, "-e", "STDIN.read; sleep 60", **options) do |*pipes|
        pid = pipes.last.pid
        block.call(*pipes)
      end
    end
    expect(extract.error.message).to include("timed out")
    expect { Process.kill(0, pid) }.to raise_error(Errno::ESRCH)
  end
end
