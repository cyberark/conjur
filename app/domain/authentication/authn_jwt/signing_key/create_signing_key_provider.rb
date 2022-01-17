module Authentication
  module AuthnJwt
    module SigningKey
      # Factory that returns the interface implementation of FetchSigningKey
      CreateSigningKeyProvider ||= CommandClass.new(
        dependencies: {
          fetch_signing_key: ::Util::ConcurrencyLimitedCache.new(
            ::Util::RateLimitedCache.new(
              ::Authentication::AuthnJwt::SigningKey::FetchCachedSigningKey.new,
              refreshes_per_interval: CACHE_REFRESHES_PER_INTERVAL,
              rate_limit_interval: CACHE_RATE_LIMIT_INTERVAL,
              logger: Rails.logger
            ),
            max_concurrent_requests: CACHE_MAX_CONCURRENT_REQUESTS,
            logger: Rails.logger
          ),
          fetch_signing_key_parameters: Authentication::AuthnJwt::SigningKey::FetchSigningKeyParametersFromVariables.new,
          build_signing_key_settings: Authentication::AuthnJwt::SigningKey::SigningKeySettingsBuilder.new,
          fetch_provider_uri_signing_key_class: Authentication::AuthnJwt::SigningKey::FetchProviderUriSigningKey,
          fetch_jwks_uri_signing_key_class: Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey,
          fetch_public_keys_signing_key_class: Authentication::AuthnJwt::SigningKey::FetchPublicKeysSigningKey,
          logger: Rails.logger
        },
        inputs: %i[authenticator_input]
      ) do
        def call
          @logger.debug(LogMessages::Authentication::AuthnJwt::SelectingSigningKeyInterface.new)
          build_signing_key_settings
          create_signing_key_provider
        end

        private

        def build_signing_key_settings
          signing_key_settings
        end

        def signing_key_settings
          @signing_key_settings ||= @build_signing_key_settings.call(
            signing_key_parameters: signing_key_parameters
          )
        end

        def signing_key_parameters
          @signing_key_parameters ||= @fetch_signing_key_parameters.call(
            authenticator_input: @authenticator_input
          )
        end

        def create_signing_key_provider
          case signing_key_settings.type
          when JWKS_URI_INTERFACE_NAME
            fetch_jwks_uri_signing_key
          when PROVIDER_URI_INTERFACE_NAME
            fetch_provider_uri_signing_key
          when PUBLIC_KEYS_INTERFACE_NAME
            fetch_public_keys_signing_key
          else
            raise Errors::Authentication::AuthnJwt::InvalidSigningKeyType, signing_key_settings.type
          end
        end

        def fetch_provider_uri_signing_key
          @logger.info(
            LogMessages::Authentication::AuthnJwt::SelectedSigningKeyInterface.new(PROVIDER_URI_INTERFACE_NAME)
          )
          @fetch_provider_uri_signing_key ||= @fetch_provider_uri_signing_key_class.new(
            provider_uri: signing_key_settings.uri,
            fetch_signing_key: @fetch_signing_key
          )
        end

        def fetch_jwks_uri_signing_key
          @logger.info(
            LogMessages::Authentication::AuthnJwt::SelectedSigningKeyInterface.new(JWKS_URI_INTERFACE_NAME)
          )
          @fetch_jwks_uri_signing_key ||= @fetch_jwks_uri_signing_key_class.new(
            jwks_uri: signing_key_settings.uri,
            cert_store: signing_key_settings.cert_store,
            fetch_signing_key: @fetch_signing_key
          )
        end

        def fetch_public_keys_signing_key
          @logger.info(
            LogMessages::Authentication::AuthnJwt::SelectedSigningKeyInterface.new(PUBLIC_KEYS_INTERFACE_NAME)
          )
          @fetch_public_keys_signing_key ||= @fetch_public_keys_signing_key_class.new(
            signing_keys: signing_key_settings.signing_keys
          )
        end
      end
    end
  end
end
