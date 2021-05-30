module Authentication
  module AuthnJwt
    module IdentityProviders
      # Provides jwt identity from information in the URL
      class IdentityFromUrlProvider < IdentityProviderInterface
        def initialize(authentication_parameters)
          @authentication_parameters = authentication_parameters
        end

        def provide_jwt_identity
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
