# frozen_string_literal: true

module Authentication
  module Base
    class RoleIdentifier
      attr_reader :role_identifier, :annotations #, :exception

      def initialize(role_identifier:, annotations: {}, exception: nil)
        @role_identifier = role_identifier
        @annotations = annotations
        # @exception = exception
      end

      def type
        @role_identifier.split(':')[1]
      end

      def account
        @role_identifier.split(':')[0]
      end

      # Role identifier within the account and type context:
      # <account>:<type>:<id>
      def id
        @role_identifier.split(':')[2]
      end

      # Essentially just an alias, but doing it this way to
      # avoid duplicate alias Rubocop warning.
      def conjur_role
        @role_identifier
      end

      def role_for_error
        type == 'host' ? "host/#{id}" : id
      end
    end
  end
end
