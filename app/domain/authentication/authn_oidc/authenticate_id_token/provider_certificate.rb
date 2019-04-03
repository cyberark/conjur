require 'uri'
require 'json'

module Authentication
  module AuthnOidc
    module AuthenticateIdToken
      class ProviderCertificate

        def fetch_certs(provider_uri)
          # provider discovery might throw exception. Let it propagate upward
          discovered_provider = discover_provider(provider_uri)
          begin
            discovered_provider.jwks
          rescue => e
            raise ProviderFetchCertificateFailed, provider_uri
          end
        end

        private

        def discover_provider(provider_uri)
          OpenIDConnect::Discovery::Provider::Config.discover!(provider_uri)
        rescue HTTPClient::ConnectTimeoutError => e
          raise ProviderDiscoveryTimeout, provider_uri
        rescue => e
          raise ProviderDiscoveryFailed, provider_uri
        end
      end
    end
  end
end
