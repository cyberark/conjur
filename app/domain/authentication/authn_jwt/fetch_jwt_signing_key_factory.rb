module Authentication
  module AuthnJwt
    # Factory that returns the interface implementation of FetchSigningKey
    class FetchJwtSigningKeyFactory

      def create(authenticator_parameters)
        @authenticator_parameters = authenticator_parameters
        validate_key_configuration

        if provider_uri_has_valid_configuration?
          Authentication::AuthnJwt::FetchProviderUriSigningKey.new(@authenticator_input,
                                                                   Rails.logger,
                                                                   Conjur::FetchRequiredSecrets.new,
                                                                   ::Resource)
        elsif jwks_uri_has_valid_configuration?
          Authentication::AuthnJwt::FetchJwksUriSigningKey.new(@authenticator_input,
                                                               Rails.logger,
                                                               OAuth::DiscoverIdentityProvider.new,
                                                               Conjur::FetchRequiredSecrets.new,
                                                               ::Resource)
        end
      end

      private

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
        @provider_uri_has_valid_configuration ||= @fetch_provider_uri_signing_key.has_valid_configuration?
      end

      def jwks_uri_has_valid_configuration?
        @jwks_uri_has_valid_configuration ||= @fetch_jwks_uri_signing_key.has_valid_configuration?
      end
    end
  end
end

