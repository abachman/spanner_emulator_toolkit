$: << File.expand_path("../lib", __FILE__)

require "spanner_emulator_toolkit"

SpannerEmulatorToolkit.configure do |config|
  config.project_id = "test-project"
  config.emulator_host = "localhost:9010"
  config.log_level = Logger::DEBUG
end

SpannerEmulatorToolkit.reset_sessions!
