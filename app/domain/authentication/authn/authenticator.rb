# frozen_string_literal: true

require 'command_class'

# default conjur authenticator
module Authentication
  module Authn
    Authenticator = CommandClass.new(
      dependencies: {
        role_cls: ::Role,
        credentials_cls: ::Credentials
      },
      inputs: [:authenticator_input]
    ) do
      extend(Forwardable)
      def_delegators(:@authenticator_input, :account, :credentials, :username)

      def call
        return false unless role_credentials

        validate_api_key
      end

      private

      def validate_api_key
        role_credentials.valid_api_key?(credentials)
      end

      def role_credentials
        @role_credentials ||= @credentials_cls[role_id]
      end

      def role_id
        @role_id ||= @role_cls.roleid_from_username(account, username)
      end
    end

    class Authenticator

      def self.requires_env_arg?
        false
      end

      def login(input)
        ::Authentication::Authn::Login.new.(authenticator_input: input)
      end

      # Authenticates a Conjur role using its id and API key
      def valid?(input)
        call(authenticator_input: input)
      end
    end
  end
end
