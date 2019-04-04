require 'uri'
require 'json'

module Authentication
  module AuthnOidc
    module AuthenticateIdToken
      class ProviderCertificate

        def fetch_certs(provider_uri)
          Rails.logger.debug("[OIDC] Fetching provider certificate from '#{provider_uri}'")

          # provider discovery might throw exception. Let it propagate upward
          discovered_provider = discover_provider(provider_uri)
          begin
            discovered_provider.jwks
          rescue => e
            raise ProviderFetchCertificateFailed.new(provider_uri, e.inspect)
          end
        end

        private

        def discover_provider(provider_uri)
          OpenIDConnect::Discovery::Provider::Config.discover!(provider_uri)
        rescue HTTPClient::ConnectTimeoutError => e
          raise ProviderDiscoveryTimeout.new(provider_uri, e.inspect)
        rescue => e
          raise ProviderDiscoveryFailed.new(provider_uri, e.inspect)
        end
      end
    end
  end
end
