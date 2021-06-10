module Authentication
  module AuthnJwt
    module SigningKey
      # Factory that returns the interface implementation of FetchSigningKey
      CreateSigningKeyInterface ||= CommandClass.new(
        dependencies: {
          fetch_provider_uri: Authentication::AuthnJwt::SigningKey::FetchProviderUriSigningKey,
          fetch_jwks_uri: Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey,
          logger: Rails.logger
        },
        inputs: %i[authentication_parameters]
      ) do

        def call
          create_signing_key
        end

        private

        def create_signing_key
          @logger.debug(LogMessages::Authentication::AuthnJwt::SelectingSigningKeyInterface.new)
          validate_key_configuration

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

        def validate_key_configuration
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatingJwtSigningKeyConfiguration.new)
          if (provider_uri_has_valid_configuration? && jwks_uri_has_valid_configuration?) ||
            (!provider_uri_has_valid_configuration? && !jwks_uri_has_valid_configuration?)
            raise Errors::Authentication::AuthnJwt::InvalidUriConfiguration.new(
              PROVIDER_URI_RESOURCE_NAME,
              JWKS_URI_RESOURCE_NAME
            )
          end
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedSigningKeyConfiguration.new)
        end

        def provider_uri_has_valid_configuration?
          return @provider_uri_has_valid_configuration if defined?(@provider_uri_has_valid_configuration)

          @provider_uri_has_valid_configuration = fetch_provider_uri_signing_key.valid_configuration?
        end

        def jwks_uri_has_valid_configuration?
          return @jwks_uri_has_valid_configuration if defined?(@jwks_uri_has_valid_configuration)

          @jwks_uri_has_valid_configuration ||= fetch_jwks_uri_signing_key.valid_configuration?
        end

        def fetch_provider_uri_signing_key
          @fetch_provider_uri_signing_key ||= @fetch_provider_uri.new(
            authentication_parameters: @authentication_parameters
          )
        end

        def fetch_jwks_uri_signing_key
          @fetch_jwks_uri_signing_key ||= @fetch_jwks_uri.new(
            authentication_parameters: @authentication_parameters
          )
        end
      end
    end
  end
end
