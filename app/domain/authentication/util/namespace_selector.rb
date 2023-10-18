# frozen_string_literal: true

module Authentication
  module Util
    class NamespaceSelector
      def self.select(authenticator_type:)
        case authenticator_type
        when 'authn'
          'Authentication::AuthnApiKey::V2'
        when 'authn-iam'
          'Authentication::AuthnAws::V2'
        when 'authn-jwt'
          'Authentication::AuthnJwt::V2'
        when 'authn-oidc'
          # 'V2' is a bit of a hack to handle the fact that
          # the original OIDC authenticator is really a
          # glorified JWT authenticator.
          'Authentication::AuthnOidc::V2'
        else
          raise "'#{authenticator_type}' is not a supported authenticator type"
          # TODO: make this dynamic based on authenticator type.
        end
      end
    end
  end
end
