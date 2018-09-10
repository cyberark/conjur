# frozen_string_literal: true

# default conjur authenticator
#
module Authentication
  module Authn

    class Authenticator < ::Dry::Struct

      def self.requires_env_arg?
        false
      end

      # optional
      #
      attribute :role_cls, ::Types::Any.default{ ::Authentication::MemoizedRole }
      attribute :credentials_cls, ::Types::Any.default { ::Credentials }

      # Authenticates a Conjur using their username and password
      def login(input)
        credentials = credentials(input)
        success = credentials&.authenticate(input.password)

        success ? credentials.api_key : nil
      end

      # Authenticates a Conjur role using its id and API key
      def valid?(input)
        credentials = credentials(input)
        credentials&.valid_api_key?(input.password)
      end

      def credentials(input)
        role_id = role_cls.roleid_from_username(input.account, input.username)
        credentials_cls[role_id]
      end
    end
  end
end
