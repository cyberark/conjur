require 'uri'
require 'json'

module Authentication
  module AuthnOidc
    module AuthenticateIdToken

      Log = LogMessages::Authentication::AuthnOidc
      Err = Errors::Authentication::AuthnOidc
      # Possible Errors Raised:
      #   ProviderDiscoveryTimeout
      #   ProviderDiscoveryFailed
      #   ProviderFetchCertificateFailed

      FetchProviderCertificate = CommandClass.new(
        dependencies: {
          logger: Rails.logger,
          discover_oidc_provider: Authentication::AuthnOidc::AuthenticateIdToken::DiscoverOIDCProvider.new
        },
        inputs: %i(provider_uri)
      ) do

        def call
          discovered_provider
          fetch_certs
        end

        private

        def discovered_provider
          @discovered_provider ||= @discover_oidc_provider.(
            provider_uri: @provider_uri
          )
        end

        def fetch_certs
          @discovered_provider.jwks.tap do
            @logger.debug(Log::FetchProviderCertsSuccess.new)
          end
        rescue => e
          raise Err::ProviderFetchCertificateFailed.new(@provider_uri, e.inspect)
        end
      end
    end
  end
end
