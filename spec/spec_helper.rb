# frozen_string_literal: true

require "nous"
require "webmock/rspec"

WebMock.disable_net_connect!

FIXTURE_PATH = File.expand_path("fixtures", __dir__)

def fixture(name)
  File.read(File.join(FIXTURE_PATH, name))
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after { Nous.reset_configuration! }
end
