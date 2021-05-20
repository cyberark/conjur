# frozen_string_literal: true

require 'command_class'

require_relative '../connect_database'

module Commands
  module DB
    Migrate ||= CommandClass.new(
      dependencies: {
        connect_database: ConnectDatabase.new
      },

      inputs: %i[]
    ) do
      def call
        # Ensure the database is available
        @connect_database.call

        system("rake db:migrate") || exit(($CHILD_STATUS.exitstatus))
      end
    end
  end
end
