module Authentication
  module AuthnJwt
    module IdentityProviders
      # Provides jwt identity from information in the URL
      class IdentityFromUrlProvider < IdentityProviderInterface
        def initialize(authentication_parameters)
          super
        end

        def jwt_identity
          raise Errors::Authentication::AuthnJwt::NoRelevantIdentityProvider unless identity_available?

          @authentication_parameters.username
        end

        def identity_available?
          !@authentication_parameters.username.blank?
        end
      end
    end
  end
end
