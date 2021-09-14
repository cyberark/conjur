require 'command_class'

module Authentication
  module AuthnJwt
    module IdentityProviders
      # Provides jwt identity from information in the URL
      IdentityFromUrlProvider = CommandClass.new(
        dependencies: {
          logger: Rails.logger
        },
        inputs: %i[jwt_authenticator_input]
      ) do
        extend(Forwardable)
        def_delegators(:@jwt_authenticator_input, :username)

        def call
          @logger.debug(
            LogMessages::Authentication::AuthnJwt::FetchingIdentityByInterface.new(
              URL_IDENTITY_PROVIDER_INTERFACE_NAME
            )
          )
          raise Errors::Authentication::AuthnJwt::IdentityMisconfigured unless username_exists?

          @logger.info(
            LogMessages::Authentication::AuthnJwt::FetchedIdentityByInterface.new(
              username,
              URL_IDENTITY_PROVIDER_INTERFACE_NAME
            )
          )

          username
        end

        private

        def username_exists?
          username.present?
        end
      end
    end
  end
end
