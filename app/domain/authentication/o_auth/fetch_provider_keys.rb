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
        # We have to wrap the call to the JWKS URI separately to accomodate
        # custom CA certs in authn-oidc
        jwks = {
          keys: Authentication::AuthnOidc::V2::Client.discover(
            provider_uri: @provider_uri,
            cert_string: @ca_cert,
            jwks: true
          )
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
