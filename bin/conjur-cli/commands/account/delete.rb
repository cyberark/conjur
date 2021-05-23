# frozen_string_literal: true

require 'command_class'

require_relative '../connect_database'

module Commands
  module Account
    Delete ||= CommandClass.new(
      dependencies: {
        connect_database: ConnectDatabase.new
      },

      inputs: %i[
        account
      ]
    ) do
      def call
        raise "No account name was provided" unless @account

        # Ensure the database is available
        @connect_database.call

        exec("rake 'account:delete[#{@account}]'")
      end
    end
  end
end
