module Authentication
  module AuthnJwt
    module SigningKey
      # This class is responsible for fetching JWK Set from provider-uri
      class FetchProviderUriSigningKey < FetchSigningKeyInterface

        def initialize(
            authentication_parameters:,
            fetch_required_secrets: Conjur::FetchRequiredSecrets.new,
            resource_class: ::Resource,
            discover_identity_provider: Authentication::OAuth::DiscoverIdentityProvider.new,
            logger: Rails.logger
          )
          @logger = logger
          @fetch_required_secrets = fetch_required_secrets
          @resource_class = resource_class
          @discover_identity_provider = discover_identity_provider

          @authentication_parameters = authentication_parameters
        end

        def valid_configuration?
          return @valid_configuration if defined?(@valid_configuration)

          @valid_configuration = provider_uri_resource_exists?
        end

        def call
          discover_provider
          fetch_provider_keys
        end

        private

        def provider_uri_resource_exists?
          !provider_uri_resource.nil?
        end

        def provider_uri_resource
          return @provider_uri_resource if @provider_uri_resource
          @logger.debug(LogMessages::Authentication::AuthnJwt::FetchingJwtConfigurationValue.new(provider_uri_variable_id))
          @provider_uri_resource = @resource_class[provider_uri_variable_id]
        end

        def provider_uri
          @provider_uri ||= provider_uri_secret[provider_uri_variable_id]
        end

        def provider_uri_secret
          @provider_uri_secret ||= @fetch_required_secrets.(resource_ids: [provider_uri_variable_id])
        end

        def provider_uri_variable_id
          @provider_uri_variable_id ||= "#{@authentication_parameters.authn_jwt_variable_id_prefix}/#{PROVIDER_URI_RESOURCE_NAME}"
        end

        def discover_provider
          @logger.info(LogMessages::Authentication::AuthnJwt::FetchingJwksFromProvider.new(provider_uri))
          discovered_provider
        end

        def discovered_provider
          @discovered_provider ||= @discover_identity_provider.call(
            provider_uri: provider_uri
          )
        end

        def fetch_provider_keys
          keys = { keys: discovered_provider.jwks }
          @logger.debug(LogMessages::Authentication::OAuth::FetchProviderKeysSuccess.new)
          keys
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
