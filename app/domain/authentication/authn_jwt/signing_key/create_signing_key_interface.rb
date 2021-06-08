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
          create
        end

        private

        def create
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
          return @provider_uri_has_valid_configuration unless @provider_uri_has_valid_configuration.nil?

          @provider_uri_has_valid_configuration ||= fetch_provider_uri_signing_key.valid_configuration?
        end

        def jwks_uri_has_valid_configuration?
          return @jwks_uri_has_valid_configuration unless @jwks_uri_has_valid_configuration.nil?

          @jwks_uri_has_valid_configuration ||= fetch_jwks_uri_signing_key.valid_configuration?
        end

        def fetch_provider_uri_signing_key
          @fetch_provider_uri_signing_key ||= @fetch_provider_uri.new(authentication_parameters: @authentication_parameters,
                                                                      logger: Rails.logger,
                                                                      fetch_required_secrets: Conjur::FetchRequiredSecrets.new,
                                                                      resource_class: ::Resource,
                                                                      discover_identity_provider: Authentication::OAuth::DiscoverIdentityProvider.new)
        end

        def fetch_jwks_uri_signing_key
          @fetch_jwks_uri_signing_key ||= @fetch_jwks_uri.new(authentication_parameters: @authentication_parameters,
                                                              logger: Rails.logger,
                                                              fetch_required_secrets: Conjur::FetchRequiredSecrets.new,
                                                              resource_class: ::Resource,
                                                              http_lib: Net::HTTP,
                                                              create_jwks_from_http_response: CreateJwksFromHttpResponse.new)
        end
      end
    end
  end
end
