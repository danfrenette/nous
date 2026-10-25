# frozen_string_literal: true

namespace :verify do
  desc "Verify the packaged Defuddle runtime outside the checkout"
  RSpec::Core::RakeTask.new(:defuddle_package) do |task|
    task.pattern = "spec/verification/defuddle_package.rb"
  end

  desc "Verify bundled Defuddle extraction and process boundaries"
  RSpec::Core::RakeTask.new(:defuddle) do |task|
    task.pattern = %w[spec/nous/extractor/defuddle_spec.rb spec/nous/extractor/defuddle/client_spec.rb spec/nous/cli_spec.rb]
  end

  desc "Verify offline retained-HTML extraction baseline"
  RSpec::Core::RakeTask.new(:retained_html) do |task|
    task.pattern = %w[spec/nous/extractor/default_spec.rb spec/nous/extractor/default/client_spec.rb spec/nous/extract_html_spec.rb]
  end

  desc "Verify detailed extraction failure visibility"
  RSpec::Core::RakeTask.new(:failure_propagation) do |task|
    task.pattern = %w[spec/verification/failure_propagation.rb spec/nous/fetch_outcomes_spec.rb spec/integration/full_pipeline_spec.rb]
  end
end
