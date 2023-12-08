# frozen_string_literal: true

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
