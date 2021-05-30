# frozen_string_literal: true

require 'command_class'

require_relative '../connect_database'

module Commands
  module Policy
    Load ||= CommandClass.new(
      dependencies: {
        connect_database: ConnectDatabase.new
      },

      inputs: %i[
        account
        file_names
      ]
    ) do
      def call
        # Ensure the database is available
        @connect_database.call

        raise('policy load failed') unless load_policy_files
      end

      private

      def load_policy_files
        @file_names.map do |file_name|
          system("rake 'policy:load[#{@account},#{file_name}]'")
        end.all?
      end
    end
  end
end
