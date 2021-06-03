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
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatingJwtSigningKeyConfiguration.new)
          validate_key_configuration

          if provider_uri_has_valid_configuration?
            @logger.debug(LogMessages::Authentication::AuthnJwt::FetchingProviderUriSigningKey.new)
            fetch_provider_uri_signing_key
          elsif jwks_uri_has_valid_configuration?
            @logger.debug(LogMessages::Authentication::AuthnJwt::FetchingJwksUriSigningKey.new)
            fetch_jwks_uri_signing_key
          end
        end

        def validate_key_configuration
          if (provider_uri_has_valid_configuration? && jwks_uri_has_valid_configuration?) ||
              (!provider_uri_has_valid_configuration? && !jwks_uri_has_valid_configuration?)
            raise Errors::Authentication::AuthnJwt::InvalidUriConfiguration.new(
              PROVIDER_URI_RESOURCE_NAME,
              JWKS_URI_RESOURCE_NAME
            )
          end
        end

        def provider_uri_has_valid_configuration?
          @provider_uri_has_valid_configuration ||= fetch_provider_uri_signing_key.jwks_uri_resource_exists
        end

        def jwks_uri_has_valid_configuration?
          @jwks_uri_has_valid_configuration ||= fetch_jwks_uri_signing_key.jwks_uri_resource_exists
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
