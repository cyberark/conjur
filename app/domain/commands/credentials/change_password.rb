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
      inputs: %i[role password client_ip]
    ) do

      def call
        change_password
        audit_success
      rescue => e
        audit_failure(e)
        raise e
      end

      private

      def change_password
        credentials.password = @password
        credentials.save(raise_on_save_failure: true)
      end

      def credentials
        @role.credentials
      end

      def audit_success
        @audit_log.log(
          ::Audit::Event::Password.new(
            user_id: @role.id,
            client_ip: @client_ip,
            success: true
          )
        )
      end

      def audit_failure(err)
        @audit_log.log(
          ::Audit::Event::Password.new(
            user_id: @role.id,
            client_ip: @client_ip,
            success: false,
            error_message: err.message
          )
        )
      end
    end
  end
end
