require 'uri'
require 'json'
require 'authentication/errors'

module Authentication
  module AuthnOidc
    module AuthenticateIdToken

      # Possible Errors Raised:
      # ProviderDiscoveryTimeout, ProviderDiscoveryFailed, ProviderFetchCertificateFailed

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
          raise_error(Authentication::AuthnOidc::ProviderDiscoveryTimeout, e)
        rescue => e
          raise_error(Authentication::AuthnOidc::ProviderDiscoveryFailed, e)
        end

        def fetch_certs
          @logger.debug("[OIDC] Fetching provider certificate from '#{@provider_uri}'")

          jwks = @discovered_provider.jwks
          @logger.debug("[OIDC] Provider certificate was fetched successfully from '#{@provider_uri}'")
          jwks
        rescue => e
          raise_error(Authentication::AuthnOidc::ProviderFetchCertificateFailed, e)
        end

        def raise_error(error_class, original_error)
          raise error_class.new(@provider_uri, original_error.inspect)
        end
      end
    end
  end
end
