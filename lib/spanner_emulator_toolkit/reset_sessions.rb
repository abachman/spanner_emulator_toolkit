# frozen_string_literal: true

require "google/cloud/spanner"

module SpannerEmulatorToolkit
  class << self
    # reset all sessions on all databases on all instances for the configured emulator project
    def reset_sessions!
      configuration.validate!

      logger.debug "resetting sessions"
      project.instances.all do |instance|
        logger.debug "instance: #{instance.path}"
        instance.databases.all do |database|
          logger.debug "  database: #{database.path}"
          each_session_for_database(database) do |session|
            logger.debug "    session: #{session.path}"
            tx = session.create_empty_transaction
            session.rollback tx.transaction_id
          rescue => e
            logger.debug "    error resetting session: #{e.details}"
          end
        end
      end
    end

    private

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
  end
end
