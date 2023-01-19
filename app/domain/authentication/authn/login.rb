# frozen_string_literal: true

require 'command_class'

module Authentication
  module Authn
    Login = CommandClass.new(
      dependencies: {
        role_cls:        ::Role,
        credentials_cls: ::Credentials
      },
      inputs:       [:authenticator_input]
    ) do

      extend Forwardable
      def_delegators :@authenticator_input, :account, :credentials, :username

      def call
        return nil unless role_credentials
        api_key
      end

      private

      def api_key
        authenticate
        @success ? role_credentials.api_key : nil
      end

      def authenticate
        @success = role_credentials.authenticate(credentials)
      end

      def role_credentials
        @role_credentials ||= @credentials_cls[role_id]
      end

      def role_id
        @role_id ||= @role_cls.roleid_from_username(account, username)
      end
    end
  end
end
