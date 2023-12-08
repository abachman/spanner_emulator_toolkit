$: << File.expand_path("../lib", __FILE__)

require "spanner_emulator_toolkit"

SpannerEmulatorToolkit.configure do |config|
  config.log_level = Logger::DEBUG
end

SpannerEmulatorToolkit.drop_instance
