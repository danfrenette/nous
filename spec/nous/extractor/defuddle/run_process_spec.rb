# frozen_string_literal: true

require "rbconfig"

RSpec.describe Nous::Extractor::Defuddle::RunProcess do
  def extract
    described_class.call(request: "retained input")
  end

  def process_fixture(code)
    allow(Open3).to receive(:popen3).and_wrap_original do |original, *args, **options, &block|
      original.call(RbConfig.ruby, "-e", code, **options, &block)
    end
  end

  it "reports a missing runtime" do
    allow(Open3).to receive(:popen3).and_raise(Errno::ENOENT)
    expect(extract.error.message).to include("Node.js")
  end

  it "does not expose process diagnostics on failure" do
    process_fixture('STDIN.read; STDERR.write("private source"); exit 1')
    expect(extract.error.message).to eq("Defuddle extraction failed")
  end

  it "returns process output without interpreting the content" do
    process_fixture("STDOUT.write(STDIN.read.reverse)")
    expect(extract.payload).to eq("tupni deniater")
  end

  it "bounds process output" do
    stub_const("#{described_class}::OUTPUT_LIMIT", 1024)
    process_fixture('STDIN.read; loop { STDOUT.write("x" * 2048); STDOUT.flush }')
    expect(extract.error.message).to include("byte limit")
  end

  it "reaps the process after success and nonzero exit" do
    ['STDIN.read; puts %q({"title":"Title","content":"<p>Body</p>","markdown":"Body"})',
      "STDIN.read; exit 1"].each_with_index do |code, index|
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
