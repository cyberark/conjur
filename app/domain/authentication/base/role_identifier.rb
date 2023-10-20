# frozen_string_literal: true

module Authentication
  module Base
    class RoleIdentifier
      attr_reader :identifier, :annotations

      def initialize(identifier:, annotations: {})
        @identifier = identifier
        @annotations = annotations
      end

      def type
        @identifier.split(':')[1]
      end

      def account
        @identifier.split(':')[0]
      end

      # Role identifier within the account and type context:
      # <account>:<type>:<id>
      def id
        @identifier.split(':')[2]
      end

      # Essentially just an alias, but doing it this way to
      # avoid duplicate alias Rubocop warning.
      # def conjur_role
      #   @role_identifier
      # end

      def role_for_error
        type == 'host' ? "host/#{id}" : id
      end
    end
  end
end
