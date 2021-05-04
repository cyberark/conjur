module Authentication
  module AuthnJwt

    JwtFetchProviderUriSigningKey = CommandClass.new(
      dependencies: {
        logger: Rails.logger,
        discover_identity_provider: OAuth::DiscoverIdentityProvider.new,
        fetch_secrets: Conjur::FetchRequiredSecrets.new
      },
      inputs: %i[authenticator_input]
    ) do
      def call
        provider_uri
        discover_provider
        fetch_provider_keys
      end

      private

      def provider_uri
        @logger.debug(LogMessages::Authentication::AuthnJwt::ProviderUriResourceNameConfiguration.new(resource_id))
        @provider_uri_secret ||= @fetch_secrets.(resource_ids: [resource_id])
        @provider_uri ||= @provider_uri_secret[resource_id]
      end

      def discover_provider
        discovered_provider
      end

      def discovered_provider
        @discovered_provider ||= @discover_identity_provider.(
          provider_uri: @provider_uri
        )
      end

      def fetch_provider_keys
        jwks = {
          keys: @discovered_provider.jwks
        }
        algs = @discovered_provider.id_token_signing_alg_values_supported
        @logger.debug(LogMessages::Authentication::OAuth::FetchProviderUriKeysSuccess.new)
        OAuth::ProviderKeys.new(jwks, algs)
      rescue => e
        raise Errors::Authentication::OAuth::FetchProviderKeysFailed.new(
          @provider_uri,
          e.inspect
        )
      end

      def resource_id
        "#{@authenticator_input.account}:variable:conjur/#{@authenticator_input.authenticator_name}/#{@authenticator_input.service_id}/#{PROVIDER_URI_RESOURCE_NAME}"
      end
    end
  end
end
