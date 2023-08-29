require 'json'

module Authentication
  module OAuth

    FetchProviderKeys = CommandClass.new(
      dependencies: {
        logger: Rails.logger,
        discover_identity_provider: DiscoverIdentityProvider.new
      },
      inputs: %i[provider_uri ca_cert]
    ) do
      def call
        discover_provider
        fetch_provider_keys
      end

      private

      def discover_provider
        discovered_provider
      end

      def discovered_provider
        @discovered_provider ||= @discover_identity_provider.(
          provider_uri: @provider_uri,
          ca_cert: @ca_cert
        )
      end

      def fetch_provider_keys
        jwks = {
          keys: @discovered_provider.jwks
        }
        algs = @discovered_provider.id_token_signing_alg_values_supported
        @logger.debug(LogMessages::Authentication::OAuth::FetchProviderKeysSuccess.new)
        ProviderKeys.new(jwks, algs)
      rescue => e
        raise Errors::Authentication::OAuth::FetchProviderKeysFailed.new(
          @provider_uri,
          e.inspect
        )
      end
    end
  end
end
