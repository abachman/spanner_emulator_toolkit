# frozen_string_literal: true

require "google/cloud/spanner"
require "concurrent"

module SpannerEmulatorToolkit
  class << self
    # raises error unless database already exists
    def client
      configuration.validate!

      thread_local_client
    end

    # Resets the client instance.
    def reset_client
      @client = nil
      self
    end

    def project
      configuration.validate!

      thread_local_project
    end

    # returns nil unless instance already exists
    def instance
      project.instance(configuration.instance_id)
    end

    def database
      instance&.database(configuration.database_id)
    end

    def instance_exists?
      !instance.nil?
    end

    def database_exists?
      !instance&.database(configuration.database_id).nil?
    end

    # no-op if instance already exists
    def create_instance
      return if instance_exists?

      logger.debug "creating instance: #{configuration.instance_id}"
      project.create_instance(
        configuration.instance_id, name: configuration.instance_id
      ).wait_until_done!
    end

    def drop_instance
      return unless instance_exists?

      logger.debug "dropping instance: #{configuration.instance_id}"
      instance.delete
    end

    # no-op if database already exists
    def create_database
      return if database_exists?

      create_instance

      logger.debug "creating database: #{configuration.database_id}"
      instance.create_database(
        configuration.database_id,
        statements: configuration.schema_statements
      ).wait_until_done!
    end

    def drop_database
      return unless database_exists?

      logger.debug "dropping database: #{configuration.database_id}"
      client.database.drop
    end

    def database_path
      client.database.path
    end

    private

    # ensure that multiple threads do not share the same client instance
    def thread_local_client
      @client ||= Concurrent::ThreadLocalVar.new(nil)
      @client.value ||= project.client(configuration.instance_id, configuration.database_id)
      @client.value
    end

    # ensure that multiple threads do not share the same project connection instance
    def thread_local_project
      @project ||= Concurrent::ThreadLocalVar.new(nil)
      @project.value ||= Google::Cloud::Spanner.new(
        project_id: configuration.project_id,
        emulator_host: configuration.emulator_host
      )
      @project.value
    end
  end
end
