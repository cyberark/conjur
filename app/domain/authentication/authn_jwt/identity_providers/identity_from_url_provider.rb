module Authentication
  module AuthnJwt
    module IdentityProviders
      # Provides jwt identity from information in the URL
      class IdentityFromUrlProvider
        def initialize(
          authentication_parameters:,
          logger: Rails.logger
        )
          @logger = logger

          @authentication_parameters = authentication_parameters
        end

        def jwt_identity
          @logger.debug(
            LogMessages::Authentication::AuthnJwt::FetchingIdentityByInterface.new(
              URL_IDENTITY_PROVIDER_INTERFACE_NAME
            )
          )
          raise Errors::Authentication::AuthnJwt::IdentityMisconfigured unless identity_available?

          @logger.info(
            LogMessages::Authentication::AuthnJwt::FetchedIdentityByInterface.new(
              @authentication_parameters.username,
              URL_IDENTITY_PROVIDER_INTERFACE_NAME
            )
          )

          @authentication_parameters.username
        end

        def identity_available?
          return @identity_available if defined?(@identity_available)

          @identity_available = username_exists?
        end

        private

        def username_exists?
          !@authentication_parameters.username.blank?
        end
      end
    end
  end
end
