module Authentication
  module AuthnJwt
    module IdentityProviders
      # Provides jwt identity from information in the URL
      class IdentityFromUrlProvider < IdentityProviderInterface
        def initialize(authentication_parameters)
          @authentication_parameters = authentication_parameters
        end

        def jwt_identity
          raise Errors::Authentication::AuthnJwt::IdentityMisconfigured unless identity_available

          @authentication_parameters.username
        end

        def identity_available
          return @identity_available unless @identity_available.nil?
          @identity_available ||= username_exists?
        end

        def username_exists?
          !@authentication_parameters.username.blank?
        end
      end
    end
  end
end
