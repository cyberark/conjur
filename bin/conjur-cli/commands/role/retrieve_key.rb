# frozen_string_literal: true

require 'command_class'

require_relative '../connect_database'

module Commands
  module Role
    RetrieveKey ||= CommandClass.new(
      dependencies: {
        connect_database: ConnectDatabase.new
      },

      inputs: %i[
        role_ids
      ]
    ) do
      def call
        # Ensure the database is available
        @connect_database.call

        fail('key retrieval failed') unless @role_ids.map do |id|
          stdout, stderr, status = Open3.capture3("rake 'role:retrieve-key[#{id}]'")

          if status.success?
            # Only print last line of stdout to omit server config logging
            puts(stdout.split("\n").last)
            true
          else
            $stderr.puts(stderr)
            false
          end
        end.all?
      end
    end
  end
end
