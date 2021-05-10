module Authentication
  module AuthnJwt
    # Factory that returns the interface implementation of FetchSigningKey
    CreateSigningKeyInterface ||= CommandClass.new(
      dependencies: {
        fetch_provider_uri: Authentication::AuthnJwt::FetchProviderUriSigningKey,
        fetch_jwks_uri: Authentication::AuthnJwt::FetchJwksUriSigningKey
      },
      inputs: %i[authenticator_parameters]
    ) do

      def call
        create
      end

      private

      def create
        validate_key_configuration

        if provider_uri_has_valid_configuration?
          fetch_provider_uri_signing_key
        elsif jwks_uri_has_valid_configuration?
          fetch_jwks_uri_signing_key
        end
      end

      def validate_key_configuration
        if (provider_uri_has_valid_configuration? and jwks_uri_has_valid_configuration?) or
          (!provider_uri_has_valid_configuration? and !jwks_uri_has_valid_configuration?)
          raise Errors::Authentication::AuthnJwt::InvalidUriConfiguration.new(
            PROVIDER_URI_RESOURCE_NAME,
            JWKS_URI_RESOURCE_NAME
          )
        end
      end

      def provider_uri_has_valid_configuration?
        @provider_uri_has_valid_configuration ||= fetch_provider_uri_signing_key.has_valid_configuration?
      end

      def jwks_uri_has_valid_configuration?
        @jwks_uri_has_valid_configuration ||= fetch_jwks_uri_signing_key.has_valid_configuration?
      end

      def fetch_provider_uri_signing_key
        @fetch_provider_uri_signing_key ||= @fetch_provider_uri.new(@authenticator_parameters,
                                                                    Rails.logger,
                                                                    Conjur::FetchRequiredSecrets.new,
                                                                    ::Resource,
                                                                    Authentication::OAuth::DiscoverIdentityProvider.new)
      end

      def fetch_jwks_uri_signing_key
        @fetch_jwks_uri_signing_key ||= @fetch_jwks_uri.new(@authenticator_parameters,
                                                            Rails.logger,
                                                            Conjur::FetchRequiredSecrets.new,
                                                            ::Resource,
                                                            Net::HTTP)
      end
    end
  end
end
