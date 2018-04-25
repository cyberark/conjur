require 'types'
require 'authentication/memoized_role'

# default conjur authenticator
#
module Authentication
  module Authn

    class Authenticator < ::Dry::Struct

      # optional
      #
      attribute :role_cls,
        ::Types::Any.default(::Authentication::MemoizedRole)
      attribute :credentials_cls, ::Types::Any.default(::Credentials)

      def valid?(input)
        role_id = role_cls.roleid_from_username(input.account, input.username)
        credentials_cls[role_id]
      end

    end

  end
end
