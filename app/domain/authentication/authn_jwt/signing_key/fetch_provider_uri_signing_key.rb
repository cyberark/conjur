module Authentication
  module AuthnJwt
    module SigningKey
      # This class is responsible for fetching JWK Set from provider-uri
      class FetchProviderUriSigningKey

        def initialize(
          provider_uri:,
          fetch_signing_key:,
          discover_identity_provider: Authentication::OAuth::DiscoverIdentityProvider.new,
          logger: Rails.logger
        )
          @logger = logger
          @discover_identity_provider = discover_identity_provider

          @provider_uri = provider_uri
          @fetch_signing_key = fetch_signing_key
        end

        def call(force_fetch:)
          @fetch_signing_key.call(
            refresh: force_fetch,
            cache_key: @provider_uri,
            signing_key_provider: self
          )
        end

        def fetch_signing_key
          discover_provider
          fetch_provider_keys
        end

        private

        def discover_provider
          @logger.info(LogMessages::Authentication::AuthnJwt::FetchingJwksFromProvider.new(@provider_uri))
          discovered_provider
        end

        def discovered_provider
          @discovered_provider ||= @discover_identity_provider.call(
            provider_uri: @provider_uri
          )
        end

        def fetch_provider_keys
          keys = { keys: discovered_provider.jwks }
          @logger.debug(LogMessages::Authentication::OAuth::FetchProviderKeysSuccess.new)
          keys
        rescue => e
          raise Errors::Authentication::OAuth::FetchProviderKeysFailed.new(
            @provider_uri,
            e.inspect
          )
        end
      end
    end
  end
end
