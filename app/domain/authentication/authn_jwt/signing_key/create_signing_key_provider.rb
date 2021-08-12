module Authentication
  module AuthnJwt
    module SigningKey
      # Factory that returns the interface implementation of FetchSigningKey
      CreateSigningKeyProvider ||= CommandClass.new(
        dependencies: {
          fetch_provider_uri_signing_key_class: Authentication::AuthnJwt::SigningKey::FetchProviderUriSigningKey,
          fetch_jwks_uri_signing_key_class: Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey,
          check_authenticator_secret_exists: Authentication::Util::CheckAuthenticatorSecretExists.new,
          logger: Rails.logger
        },
        inputs: %i[authentication_parameters]
      ) do

        def call
          @logger.debug(LogMessages::Authentication::AuthnJwt::SelectingSigningKeyInterface.new)
          validate_key_configuration
          create_signing_key_provider
        end

        private

        def validate_key_configuration
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatingJwtSigningKeyConfiguration.new)
          if both_sigining_keys_providers_configured || neither_sigining_keys_providers_configured
            raise Errors::Authentication::AuthnJwt::InvalidUriConfiguration.new(
              PROVIDER_URI_RESOURCE_NAME,
              JWKS_URI_RESOURCE_NAME
            )
          end
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedSigningKeyConfiguration.new)
        end

        def both_sigining_keys_providers_configured
          provider_uri_has_valid_configuration? && jwks_uri_has_valid_configuration?
        end

        def neither_sigining_keys_providers_configured
          !provider_uri_has_valid_configuration? && !jwks_uri_has_valid_configuration?
        end

        def provider_uri_has_valid_configuration?
          return @provider_uri_has_valid_configuration if defined?(@provider_uri_has_valid_configuration)

          @provider_uri_has_valid_configuration = @check_authenticator_secret_exists.call(
            conjur_account: @authentication_parameters.account,
            authenticator_name: @authentication_parameters.authenticator_name,
            service_id: @authentication_parameters.service_id,
            var_name: PROVIDER_URI_RESOURCE_NAME
          )
        end

        def jwks_uri_has_valid_configuration?
          return @jwks_uri_has_valid_configuration if defined?(@jwks_uri_has_valid_configuration)

          @jwks_uri_has_valid_configuration ||= @check_authenticator_secret_exists.call(
            conjur_account: @authentication_parameters.account,
            authenticator_name: @authentication_parameters.authenticator_name,
            service_id: @authentication_parameters.service_id,
            var_name: JWKS_URI_RESOURCE_NAME
          )
        end

        def fetch_provider_uri_signing_key
          @fetch_provider_uri_signing_key ||= @fetch_provider_uri_signing_key_class.new(
            authentication_parameters: @authentication_parameters
          )
        end

        def fetch_jwks_uri_signing_key
          @fetch_jwks_uri_signing_key ||= @fetch_jwks_uri_signing_key_class.new(
            authentication_parameters: @authentication_parameters
          )
        end

        def create_signing_key_provider
          if provider_uri_has_valid_configuration?
            @logger.info(
              LogMessages::Authentication::AuthnJwt::SelectedSigningKeyInterface.new(PROVIDER_URI_INTERFACE_NAME)
            )
            fetch_provider_uri_signing_key
          elsif jwks_uri_has_valid_configuration?
            @logger.info(
              LogMessages::Authentication::AuthnJwt::SelectedSigningKeyInterface.new(JWKS_URI_INTERFACE_NAME)
            )
            fetch_jwks_uri_signing_key
          end
        end
      end
    end
  end
end
