require 'json'

module Authentication
  module AuthnOidc

    Log = LogMessages::Authentication::AuthnOidc
    Err = Errors::Authentication::AuthnOidc
    # Possible Errors Raised:
    #   ProviderDiscoveryTimeout
    #   ProviderDiscoveryFailed
    #   ProviderFetchCertificateFailed

    FetchProviderCertificates = CommandClass.new(
      dependencies: {
        logger:                 Rails.logger,
        discover_oidc_provider: Authentication::AuthnOidc::DiscoverOIDCProvider.new
      },
      inputs:       %i(provider_uri)
    ) do

      def call
        discover_provider
        fetch_certs
      end

      private

      def discover_provider
        discovered_provider
      end

      def discovered_provider
        @discovered_provider ||= @discover_oidc_provider.(
          provider_uri: @provider_uri
        )
      end

      def fetch_certs
        jwks = {
          keys: @discovered_provider.jwks
        }
        algs = @discovered_provider.id_token_signing_alg_values_supported
        ProviderCertificates.new(jwks, algs)
      rescue => e
        raise Err::ProviderFetchCertificateFailed.new(@provider_uri, e.inspect)
      end
    end
  end
end
