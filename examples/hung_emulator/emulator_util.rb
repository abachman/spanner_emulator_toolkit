# What if instead of opening and rolling back transactions, we release every session?

require "rubygems"
require "google/cloud/spanner"

# patch the service to add a missing method
module Google
  module Cloud
    module Spanner
      class Service
        # add a missing list_sessions method
        # @param database [String] in the form of a full Spanner identifier like
        #                          "project/.../instance/.../database/..."
        def list_sessions(database:, call_options: nil, token: nil, max: nil)
          opts = default_options call_options: call_options
          request = {
            database: database,
            page_size: max,
            page_token: token
          }
          paged_enum = service.list_sessions request, opts
          paged_enum.response
        end
      end
    end
  end
end

module EmulatorUtil
  PROJECT_ID = ENV["SPANNER_PROJECT_ID"]
  INSTANCE_ID = ENV["SPANNER_INSTANCE_ID"]
  DATABASE_ID = ENV["SPANNER_DATABASE_ID"]
  EMULATOR_HOST = ENV["SPANNER_EMULATOR_HOST"]

  extend self

  attr_accessor :logger

  def project
    @project ||= Google::Cloud::Spanner.new(
      project_id: PROJECT_ID,
      emulator_host: EMULATOR_HOST,
      timeout: 5
    )
  end

  def client
    project.client(INSTANCE_ID, DATABASE_ID)
  end

  def setup!
    unless project.instance(INSTANCE_ID)
      project
        .create_instance(INSTANCE_ID, name: INSTANCE_ID, nodes: 1)
        .wait_until_done!
    end

    unless project.instance(INSTANCE_ID).database(DATABASE_ID)
      schema = "CREATE TABLE Customers (Id STRING(36) NOT NULL) PRIMARY KEY (Id)"
      project
        .instance(INSTANCE_ID)
        .create_database(DATABASE_ID, statements: [schema])
        .wait_until_done!
    end
  end

  # open an empty transaction and rollback immediately on every session in the emulator
  def reset_all_emulator_transactions!
    project.instances.all do |instance|
      puts "instance: #{id(instance)}"
      instance.databases.all do |database|
        puts "  database: #{id(database)}"
        each_session_for_database(database) do |session|
          puts "    resetting session: #{id(session)}"
          tx = session.create_empty_transaction
          session.rollback tx.transaction_id
        rescue => e
          puts "    error resetting session: #{e.details}"
          raise
        end
      end
    end
  end

  # call .release! on every session in the emulator
  def release_all_emulator_sessions!
    project.instances.all do |instance|
      puts "instance: #{id(instance)}"
      instance.databases.all do |database|
        puts "  database: #{id(database)}"
        each_session_for_database(database) do |session|
          puts "    releasing session: #{id(session)}"
          session.release!
        rescue => e
          puts "    error resetting session: #{e.details}"
          raise
        end
      end
    end
  end

  def each_session_for_database(database)
    # patched method, paginated
    session_result = database.service.list_sessions(database: database.path)
    next_page_token = session_result.next_page_token

    loop do
      session_result.sessions.each do |grpc_session|
        yield Google::Cloud::Spanner::Session.new(grpc_session, database.service)
      end

      break if next_page_token.empty?

      session_result = database.service.list_sessions(database: database.path, token: next_page_token)
      next_page_token = session_result.next_page_token
    end
  end

  def id(path_haver)
    path_haver.path.split("/").last(2).join("/")
  end

  def puts(message)
    if logger
      logger.debug(message)
    end
  end
end
