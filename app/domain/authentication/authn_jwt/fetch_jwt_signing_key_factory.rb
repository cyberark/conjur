module Authentication
  module AuthnJwt
    # Factory that returns the interface implementation of FetchSigningKey
    class FetchJwtSigningKeyFactory

      def initialize(authenticator_parameters)
        @authenticator_input = authenticator_parameters
        @fetch_provider_uri_signing_key = Authentication::AuthnJwt::FetchProviderUriSigningKey.new(@authenticator_input)
        @fetch_jwks_uri_signing_key = Authentication::AuthnJwt::FetchJwksUriSigningKey.new(@authenticator_input)
      end

      def create
        validate_key_configuration

        if provider_uri_is_valid?
          @fetch_provider_uri_signing_key
        elsif jwks_uri_is_valid?
          @fetch_jwks_uri_signing_key
        end
      end

      private

      def validate_key_configuration
        if (provider_uri_is_valid? and jwks_uri_is_valid?) or
          (!provider_uri_is_valid? and !jwks_uri_is_valid?)
          raise Errors::Authentication::AuthnJwt::InvalidUriConfiguration.new(
            PROVIDER_URI_RESOURCE_NAME,
            JWKS_URI_RESOURCE_NAME
          )
        end
      end

      def provider_uri_is_valid?
        @provider_uri_resource_exists ||= @fetch_provider_uri_signing_key.has_valid_configuration?
      end

      def jwks_uri_is_valid?
        @jwks_uri_resource_exists ||= @fetch_jwks_uri_signing_key.has_valid_configuration?
      end
    end
  end
end

