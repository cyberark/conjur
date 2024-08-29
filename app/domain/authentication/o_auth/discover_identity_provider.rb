module Authentication
  module OAuth
    # Object to match the previously used `OpenIDConnect::Discovery::Provider::Config::Resource`
    # object used as part of the OpenIDConnect library. This is needed until we can fully
    # port all existing JWT based authenticators to the new authenticator architecture.
    DiscoveryProvider = Struct.new(:jwks, :supported_algorithms, keyword_init: true)

    DiscoverIdentityProvider = CommandClass.new(
      dependencies: {
        logger: Rails.logger,
        client: Authentication::Util::NetworkTransporter
      },
      inputs: %i[provider_uri ca_cert]
    ) do
      def call
        log_provider_uri
        discover_provider
      end

      private

      def log_provider_uri
        @logger.debug(
          LogMessages::Authentication::OAuth::IdentityProviderUri.new(
            @provider_uri
          )
        )
      end

      # Returns an mocked version of OpenIDConnect::Discovery::Provider::Config::Resource
      # instance. While this leaks 3rd party code into ours, the only time this Resource
      # is used is inside of FetchProviderKeys. This is unlikely to change, and hence
      # unlikely to be a problem.
      def discover_provider
        response = @client.new(hostname: @provider_uri, ca_certificate: @ca_cert).get("#{@provider_uri}/.well-known/openid-configuration").bind do |endpoint|
          @logger.debug(LogMessages::Authentication::OAuth::IdentityProviderDiscoverySuccess.new)
          @client.new(hostname: endpoint['jwks_uri'], ca_certificate: @ca_cert).get(endpoint['jwks_uri']).bind do |jwks|
            return DiscoveryProvider.new(
              jwks: jwks['keys'],
              supported_algorithms: endpoint['id_token_signing_alg_values_supported']
            )
          end
        end

        if response.exception.is_a?(Errno::ETIMEDOUT)
          raise Errors::Authentication::OAuth::ProviderDiscoveryTimeout.new(
            @provider_uri,
            response.exception
          )
        else
          raise Errors::Authentication::OAuth::ProviderDiscoveryFailed.new(
            @provider_uri,
            response.exception
          )
        end
      end
    end
  end
end
