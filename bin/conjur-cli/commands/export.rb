# frozen_string_literal: true

require 'command_class'

require_relative './connect_database'

module Commands
  Export ||= CommandClass.new(
    dependencies: {
      connect_database: ConnectDatabase.new
    },

    inputs: %i[
      out_dir
      label
    ]
  ) do
    def call
      # Ensure the database is available
      @connect_database.call

      exec(%Q(rake export["#{@out_dir}","#{@label}"]))
    end
  end
end
