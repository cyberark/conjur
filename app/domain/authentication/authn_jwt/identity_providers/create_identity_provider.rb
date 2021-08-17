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
        inputs: %i[jwt_authenticator_input]
      ) do
        extend(Forwardable)
        def_delegators(:@jwt_authenticator_input, :service_id, :authenticator_name, :account)

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
            conjur_account: account,
            authenticator_name: authenticator_name,
            service_id: service_id,
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
            jwt_authenticator_input: @jwt_authenticator_input
          )
        end

        def identity_should_be_in_url?
          @jwt_authenticator_input.username.present?
        end

        def identity_from_url_provider
          @logger.info(
            LogMessages::Authentication::AuthnJwt::SelectedIdentityProviderInterface.new(
              URL_IDENTITY_PROVIDER_INTERFACE_NAME
            )
          )

          @identity_from_url_provider_class.new(
            jwt_authenticator_input: @jwt_authenticator_input
          )
        end
      end
    end
  end
end
