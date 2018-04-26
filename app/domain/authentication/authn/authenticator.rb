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
      attribute :role_cls,
        ::Types::Any.default{ ::Authentication::MemoizedRole }
      attribute :credentials_cls, ::Types::Any.default { ::Credentials }

      def valid?(input)
        role_id = role_cls.roleid_from_username(input.account, input.username)
        credentials = credentials_cls[role_id]
        credentials.valid_api_key?(input.password)
      end

    end

  end
end
