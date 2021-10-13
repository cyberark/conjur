# frozen_string_literal: true

require 'command_class'

require_relative '../connect_database'

module Commands
  module Account
    Create ||= CommandClass.new(
      dependencies: {
        connect_database: ConnectDatabase.new
      },

      inputs: %i[
        account
        password_from_stdin
      ]
    ) do
      def call
        # Create a new account named 'default' if no name is provided
        @account ||= 'default'

        # Ensure the database is available
        @connect_database.call

        if @password_from_stdin
          # Rake is interpreting raw commas in the password as
          # delimiting addtional arguments to rake itself. 
          # Reference: https://github.com/ruby/rake/blob/a842fb2c30cc3ca80803fba903006b1324a62e9a/lib/rake/application.rb#L163
          password = stdin_input.gsub(',', '\,')
          exec("rake 'account:create_with_password[#{@account},#{password}]'")
        else
          exec("rake 'account:create[#{@account}]'")
        end
      end

      def stdin_input
        raise "Please provide an input via STDIN" if $stdin.tty?
      
        $stdin.read.force_encoding('ASCII-8BIT')
      end
    end
  end
end
