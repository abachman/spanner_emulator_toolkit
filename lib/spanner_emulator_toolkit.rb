# frozen_string_literal: true

require_relative "spanner_emulator_toolkit/version"
require_relative "spanner_emulator_toolkit/configuration"
require_relative "spanner_emulator_toolkit/client"
require_relative "spanner_emulator_toolkit/reset_sessions"
require_relative "spanner_emulator_toolkit/google_cloud_spanner_ext/service"

module SpannerEmulatorToolkit
  class Error < StandardError; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def logger
      configuration.logger
    end
  end
end
