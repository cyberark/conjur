# frozen_string_literal: true

require 'command_class'

require_relative '../connect_database'

module Commands
  module Role
    ResetPassword ||= CommandClass.new(
      dependencies: {
        connect_database: ConnectDatabase.new
      },

      inputs: %i[
        role_id
      ]
    ) do
      def call
        # Ensure the database is available
        @connect_database.call

        stdout, stderr, status = Open3.capture3("rake 'role:reset-password[#{@role_id}]'")

        if status.success?
          # Only print last line of stdout to omit server config logging
          puts(stdout.split("\n"))
          true
        else
          $stderr.puts(stderr)
          false
        end
      end
    end
  end
end
