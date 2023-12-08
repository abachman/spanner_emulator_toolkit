$: << File.expand_path("../lib", __FILE__)

require "spanner_emulator_toolkit"

SpannerEmulatorToolkit.configure do |config|
  config.schema = File.read File.expand_path("../spec/schema.sql", __dir__)
  config.log_level = Logger::DEBUG
end

SpannerEmulatorToolkit.create_database
