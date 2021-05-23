# frozen_string_literal: true

require 'command_class'

require_relative '../connect_database'

module Commands
  module Policy
    Watch ||= CommandClass.new(
      dependencies: {
        connect_database: ConnectDatabase.new
      },

      inputs: %i[
        account
        file_name
      ]
    ) do
      def call
        # Ensure the database is available
        @connect_database.call

        exec("rake 'policy:watch[#{@account},#{@file_name}]'")
      end
    end
  end
end
