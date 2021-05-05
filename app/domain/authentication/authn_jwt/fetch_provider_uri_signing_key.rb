module Authentication
  module AuthnJwt
    # This class is responsible for fetching JWK Set from provider-uri
    class FetchProviderUriSigningKey < FetchSigningKeyInterface

      def initialize(authenticator_input)
        @logger = Rails.logger
        @discover_identity_provider = OAuth::DiscoverIdentityProvider.new
        @fetch_required_secrets = Conjur::FetchRequiredSecrets.new
        @resource_class = ::Resource
        @authenticator_input = authenticator_input
      end

      def has_valid_configuration
        @provier_uri_resource_exists ||= provider_uri_resource_exists?
      end

      def fetch_signing_key
        discover_provider
        fetch_provider_keys
      end

      private

      def provider_uri_resource_exists?
        !provider_uri_resource.nil?
      end

      def provider_uri_resource
        @provider_uri_resource ||= resource(PROVIDER_URI_RESOURCE_NAME)
      end

      def resource(resource_name)
        @resource_class[resource_id(resource_name)]
      end

      def discover_provider
        discovered_provider
      end

      def discovered_provider
        @discovered_provider ||= @discover_identity_provider.(
          provider_uri: provider_uri
        )
      end

      def provider_uri
        @logger.debug(LogMessages::Authentication::AuthnJwt::ProviderUriResourceNameConfiguration.new(provider_uri_resource_id))
        @provider_uri ||= provider_uri_secret[provider_uri_resource_id]
      end

      def provider_uri_secret
        @provider_uri_secret ||= @fetch_required_secrets.(resource_ids: [provider_uri_resource_id])
      end

      def provider_uri_resource_id
        "#{@authenticator_input.account}:variable:conjur/#{@authenticator_input.authenticator_name}/#{@authenticator_input.service_id}/#{PROVIDER_URI_RESOURCE_NAME}"
      end

      def fetch_provider_keys
        jwks = {
          keys: discovered_provider.jwks
        }
        algs = discovered_provider.id_token_signing_alg_values_supported
        @logger.debug(LogMessages::Authentication::OAuth::FetchProviderUriKeysSuccess.new)
        OAuth::ProviderKeys.new(jwks, algs)
      rescue => e
        raise Errors::Authentication::OAuth::FetchProviderKeysFailed.new(
          @provider_uri,
          e.inspect
        )
      end
    end
  end
end
