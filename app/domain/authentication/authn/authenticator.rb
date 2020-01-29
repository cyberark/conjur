# frozen_string_literal: true

# default conjur authenticator
#
module Authentication
  module Authn

    class Authenticator

      def self.requires_env_arg?
        false
      end

      def initialize(role_cls: Role, credentials_cls: ::Credentials)
        @role_cls = role_cls
        @credentials_cls = credentials_cls
      end

      def login(input)
        creds = credentials(input)
        return nil unless creds

        success = creds.authenticate(input.credentials)
        success ? creds.api_key : nil
      end

      # Authenticates a Conjur role using its id and API key
      def valid?(input)
        creds = credentials(input)
        return nil unless creds
        
        creds.valid_api_key?(input.credentials)
      end

      def credentials(input)
        role_id = @role_cls.roleid_from_username(input.account, input.username)
        @credentials_cls[role_id]
      end
    end
  end
end
