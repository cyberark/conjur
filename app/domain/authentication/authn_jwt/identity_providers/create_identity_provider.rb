require 'command_class'

module Authentication
  module AuthnJwt
    module IdentityProviders
      CreateIdentityProvider = CommandClass.new(
        dependencies: {
          identity_from_url_provider_class: Authentication::AuthnJwt::IdentityProviders::IdentityFromUrlProvider,
          identity_from_decoded_token_class: Authentication::AuthnJwt::IdentityProviders::IdentityFromDecodedTokenProvider,
          check_authenticator_secret_exists: Authentication::Util::CheckAuthenticatorSecretExists.new,
          logger: Rails.logger
        },
        inputs: %i[authentication_parameters]
      ) do
        # Factory returning jwt identity provider relevant for the authentication request.
        def call
          create_identity_provider
        end

        private

        def create_identity_provider
          @logger.debug(LogMessages::Authentication::AuthnJwt::SelectingIdentityProviderInterface.new)

          if identity_should_be_in_token? and !identity_should_be_in_url?
            return identity_from_decoded_token_provider
          elsif identity_should_be_in_url? and !identity_should_be_in_token?
            return identity_from_url_provider
          else
            raise Errors::Authentication::AuthnJwt::IdentityMisconfigured
          end
        end

        def identity_should_be_in_token?
          # defined? is needed for memoization of boolean value
          return @identity_should_be_in_token if defined?(@identity_should_be_in_token)

          @identity_should_be_in_token = @check_authenticator_secret_exists.call(
            conjur_account: @authentication_parameters.account,
            authenticator_name: @authentication_parameters.authenticator_name,
            service_id: @authentication_parameters.service_id,
            var_name: TOKEN_APP_PROPERTY_VARIABLE
          )
        end

        def identity_from_decoded_token_provider
          @logger.info(
            LogMessages::Authentication::AuthnJwt::SelectedIdentityProviderInterface.new(
              TOKEN_IDENTITY_PROVIDER_INTERFACE_NAME
            )
          )

          @identity_from_decoded_token_class.new(
            authentication_parameters: @authentication_parameters
          )
        end

        def identity_should_be_in_url?
          @authentication_parameters.username.present?
        end

        def identity_from_url_provider
          @logger.info(
            LogMessages::Authentication::AuthnJwt::SelectedIdentityProviderInterface.new(
              URL_IDENTITY_PROVIDER_INTERFACE_NAME
            )
          )

          @identity_from_url_provider_class.new(
            authentication_parameters: @authentication_parameters
          )
        end
      end
    end
  end
end
