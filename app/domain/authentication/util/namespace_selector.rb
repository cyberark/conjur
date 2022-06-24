# frozen_string_literal: true
module Authentication
  module Util
    class NamespaceSelector
      def self.select(authenticator_type:)
        case authenticator_type
        when 'authn-oidc'
          # 'V2' is a bit of a hack to handle the fact that
          # the original OIDC authenticator is really a
          # glorified JWT authenticator.
          'Authentication::AuthnOidc::V2'
        else
          raise "#{authenticator_type} is not supported"
          # TODO: make this dynamic based on authenticator type.
        end
      end
    end
  end
end
