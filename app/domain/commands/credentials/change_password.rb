# frozen_string_literal: true

require 'command_class'

module Commands
  module Credentials

    ChangePassword ||= CommandClass.new(
      dependencies: {
        audit_log: ::Audit.logger
      },

      # `role` is not a pure input, but comes with an implicit database
      # dependency that it will use to save the new password.
      # This should be addressed to make the database dependency explicit:
      # https://github.com/cyberark/conjur/issues/1611
      inputs: %i(role password)
    ) do

      def call
        change_password
      end

      private

      def change_password
        credentials.password = @password
        credentials.save(raise_on_save_failure: true)
      end

      def credentials
        @role.credentials
      end
    end
  end
end
