# frozen_string_literal: true

module Authentication
  module Util
    class NamespaceSelector
      def self.select(authenticator_type:, pkce_support_enabled: Rails.configuration.feature_flags.enabled?(:pkce_support))
        case authenticator_type
        when 'authn-oidc'
          if pkce_support_enabled
            'Authentication::AuthnOidc::PkceSupportFeature'
          else
            # 'V2' is a bit of a hack to handle the fact that
            # the original OIDC authenticator is really a
            # glorified JWT authenticator.
            'Authentication::AuthnOidc::V2'
          end
        else
          raise "'#{authenticator_type}' is not a supported authenticator type"
          # TODO: make this dynamic based on authenticator type.
        end
      end
    end
  end
end
