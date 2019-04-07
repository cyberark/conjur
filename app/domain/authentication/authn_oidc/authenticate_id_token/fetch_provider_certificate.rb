require 'uri'
require 'json'

module Authentication
  module AuthnOidc
    module AuthenticateIdToken
      FetchProviderCertificate = CommandClass.new(
        dependencies: {
          logger: Rails.logger
        },
        inputs: %i(provider_uri)
      ) do

        def call
          # provider discovery might throw exception. Let it propagate upward
          discover_provider
          fetch_certs
        end

        private

        def discover_provider
          @logger.debug("[OIDC] Discovering provider '#{@provider_uri}'")

          @discovered_provider = OpenIDConnect::Discovery::Provider::Config.discover!(@provider_uri)
        rescue HTTPClient::ConnectTimeoutError => e
          raise ProviderDiscoveryTimeout.new(@provider_uri, e.inspect)
        rescue => e
          raise ProviderDiscoveryFailed.new(@provider_uri, e.inspect)
        end

        def fetch_certs
          @logger.debug("[OIDC] Fetching provider certificate from '#{@provider_uri}'")

          jwks = @discovered_provider.jwks
          @logger.debug("[OIDC] Provider certificate was fetched successfully from '#{@provider_uri}'")
          jwks
        rescue => e
          raise ProviderFetchCertificateFailed.new(@provider_uri, e.inspect)
        end
      end
    end
  end
end
