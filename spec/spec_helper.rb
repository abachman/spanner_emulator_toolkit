# frozen_string_literal: true

require "spanner_emulator_toolkit"
require "debug"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    SpannerEmulatorToolkit.configure do |config|
      config.project_id = "test-project"
      config.instance_id = "test-instance"
      config.database_id = "test-database-#{Time.now.to_i}"
      config.emulator_host = "localhost:9010"
    end
  end
end
