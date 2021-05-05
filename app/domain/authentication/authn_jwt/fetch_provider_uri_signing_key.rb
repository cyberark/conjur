module Authentication
  module AuthnJwt
    # This class is responsible for fetching JWK Set from provider-uri
    class FetchProviderUriSigningKey < FetchSigningKeyInterface

      def initialize(authenticator_parameters,
                     logger,
                     fetch_required_secrets,
                     resource_class)
        @logger = logger
        @resource_id = authenticator_parameters.authenticator_resource_id
        @fetch_required_secrets = fetch_required_secrets
        @resource_class = resource_class
        @fetch_provider_key = Authentication::OAuth::FetchProviderKeys.new
      end

      def has_valid_configuration?
        @provier_uri_resource_exists ||= provider_uri_resource_exists?
      end

      def fetch_signing_key
        @fetch_provider_key.call(provider_uri)
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

      def provider_uri
        @logger.debug(LogMessages::Authentication::AuthnJwt::ProviderUriResourceNameConfiguration.new(provider_uri_resource_id))
        @provider_uri ||= provider_uri_secret[provider_uri_resource_id]
      end

      def provider_uri_secret
        @provider_uri_secret ||= @fetch_required_secrets.(resource_ids: [provider_uri_resource_id])
      end

      def provider_uri_resource_id
        "#{@resource_id}/#{PROVIDER_URI_RESOURCE_NAME}"
      end
    end
  end
end
