module SpannerEmulatorToolkit
  class Configuration
    # Spanner settings
    attr_accessor :project_id, :instance_id, :database_id, :emulator_host, :schema

    # Generic settings
    attr_accessor :logger, :log_level

    def initialize
      @instance_id = "example-instance"
      @database_id = "example-database"
    end

    def validate!
      load_from_env
      prepare_logger

      %w[project_id instance_id database_id emulator_host].each do |attr|
        raise "configuration.#{attr} must be set" unless send(attr)
      end
    end

    def schema_statements
      return [] unless schema

      schema.split(";").map(&:strip).reject(&:empty?)
    end

    private

    def load_from_env
      %w[project_id instance_id database_id emulator_host].each do |attr|
        env_key = "SPANNER_#{attr.upcase}"
        if ENV[env_key] && !send(attr)
          send("#{attr}=", ENV[env_key])
        end
      end
    end

    def colorized(text, logger_severity)
      case logger_severity
      when "ERROR"
        "\e[31m#{text}\e[0m"
      when "DEBUG"
        "\e[32m#{text}\e[0m"
      when "WARN"
        "\e[33m#{text}\e[0m"
      when "INFO"
        "\e[34m#{text}\e[0m"
      else
        text
      end
    end

    def prepare_logger
      if logger.nil?
        self.logger = Logger.new($stdout)
        logger.formatter = proc do |severity, datetime, progname, msg|
          [
            colorized("[SpannerEmulatorToolkit #{datetime.strftime("%Y-%m-%d %H:%M:%S")}]", severity),
            colorized(severity, severity),
            msg
          ].join(" ") + "\n"
        end
      end

      logger.level = (log_level || Logger::ERROR)
    end
  end
end
