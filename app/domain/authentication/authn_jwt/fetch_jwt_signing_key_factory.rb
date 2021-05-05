module Authentication
  module AuthnJwt
    # Factory that returns the interface implementation of FetchSigningKey
    class FetchJwtSigningKeyFactory

      def initialize
        @fetch_provider_uri_signing_key = FetchProviderUriSigningKey.new(@authenticator_input)
        @fetch_jwks_uri_signing_key = FetchJwksUriSigningKey.new(@authenticator_input)
      end

      def create(authenticator_input)
        @authenticator_input = authenticator_input

        select_fetch_key_method

        case @selected_fetch_key_method
        when PROVIDER_URI_RESOURCE_NAME
          @fetch_provider_uri_signing_key
        when JWKS_URI_RESOURCE_NAME
          @fetch_jwks_uri_signing_key
        else
          raise("Fetch key method #{@selected_fetch_key_method} does not exist.")
        end
      end

      private

      def select_fetch_key_method
        validate_key_configuration

        if provider_uri_resource_exists?
          @selected_fetch_key_method = PROVIDER_URI_RESOURCE_NAME
        elsif jwks_uri_resource_exists?
          @selected_fetch_key_method = JWKS_URI_RESOURCE_NAME
        end
      end

      def validate_key_configuration
        if (@provider_uri_resource_exists and @jwks_uri_resource_exists) or
          (!@provider_uri_resource_exists and !@jwks_uri_resource_exists)
          raise Errors::Authentication::AuthnJwt::InvalidUriConfiguration.new(
            PROVIDER_URI_RESOURCE_NAME,
            JWKS_URI_RESOURCE_NAME
          )
        end
      end

      def provider_uri_resource_exists?
        @provider_uri_resource_exists ||= @fetch_provider_uri_signing_key.has_valid_configuration?
      end

      def jwks_uri_resource_exists?
        @jwks_uri_resource_exists ||= @fetch_jwks_uri_signing_key.has_valid_configuration?
      end
    end
  end
end

