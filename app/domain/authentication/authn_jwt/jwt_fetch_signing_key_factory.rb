module Authentication
  module AuthnJwt
    # Factory that returns the interface implementation of FetchSigningKey
    class JwtFetchSigningKeyFactory
      FETCH_SIGNING_KEY_METHODS = {
        "provider-uri" => JwtFetchProviderUriSigningKey,
        "jwks-uri" => JwtFetchJwksUriSigningKey
      }

      def signin_key_implementation(authenticator_input)
        @authenticator_input = authenticator_input

        select_fetch_key_method
        FETCH_SIGNING_KEY_METHODS[@selected_fetch_key_method].new || raise("Fetch key method #{@selected_fetch_key_method} does not exist.")
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
        if (provider_uri_resource_exists? and jwks_uri_resource_exists?) or
          (!provider_uri_resource_exists? and !jwks_uri_resource_exists?)
          raise Errors::Authentication::AuthnJwt::InvalidIssuerConfiguration.new(
            PROVIDER_URI_RESOURCE_NAME,
            JWKS_URI_RESOURCE_NAME
          )
        end
      end

      def provider_uri_resource_exists?
        !provider_uri_resource.nil?
      end

      def jwks_uri_resource_exists?
        !jwks_uri_resource.nil?
      end

      def provider_uri_resource
        @provider_uri_resource ||= resource(PROVIDER_URI_RESOURCE_NAME)
      end

      def jwks_uri_resource
        @jwks_uri_resource ||= resource(JWKS_URI_RESOURCE_NAME)
      end

      def resource(resource_name)
        ::Resource[resource_id(resource_name)]
      end

      def resource_id(resource_name)
        "#{@authenticator_input.account}:variable:conjur/#{@authenticator_input.authenticator_name}/#{@authenticator_input.service_id}/#{resource_name}"
      end
    end
  end
end

