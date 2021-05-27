module Authentication
  module AuthnJwt
    module SigningKey
      # This class is responsible for fetching JWK Set from provider-uri
      class FetchProviderUriSigningKey < FetchSigningKeyInterface

        def initialize(authentication_parameters:,
                       logger:,
                       fetch_required_secrets:,
                       resource_class:,
                       discover_identity_provider:)
          @logger = logger
          @resource_id = authentication_parameters.authenticator_resource_id
          @fetch_required_secrets = fetch_required_secrets
          @resource_class = resource_class
          @discover_identity_provider = discover_identity_provider
        end

        def has_valid_configuration?
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
          @provider_uri_resource ||= resource
        end

        def resource
          @logger.debug(LogMessages::Authentication::AuthnJwt::FetchingJwtConfigurationValue.new(provider_uri_resource_id))
          @resource_class[provider_uri_resource_id]
        end

        def provider_uri
          @provider_uri ||= provider_uri_secret[provider_uri_resource_id]
        end

        def provider_uri_secret
          @provider_uri_secret ||= @fetch_required_secrets.(resource_ids: [provider_uri_resource_id])
        end

        def provider_uri_resource_id
          "#{@resource_id}/#{PROVIDER_URI_RESOURCE_NAME}"
        end

        def discover_provider
          discovered_provider
        end

        def discovered_provider
          @logger.debug(LogMessages::Authentication::AuthnJwt::FetchingJwksFromProvider.new(provider_uri))
          @discovered_provider ||= @discover_identity_provider.(
            provider_uri: provider_uri
          )
        end

        def fetch_provider_keys
          @logger.debug(LogMessages::Authentication::OAuth::FetchProviderKeysSuccess.new)
          { keys: @discovered_provider.jwks }
        rescue => e
          raise Errors::Authentication::OAuth::FetchProviderKeysFailed.new(
            @provider_uri,
            e.inspect
          )
        end
      end
    end
  end
end
