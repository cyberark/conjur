module Authentication
  module AuthnOidc

    Err = Errors::Authentication::AuthnOidc
    # Possible Errors Raised:
    #   ProviderDiscoveryTimeout
    #   ProviderDiscoveryFailed

    ValidateStatus = CommandClass.new(
      dependencies: {
        fetch_oidc_secrets: AuthnOidc::Util::FetchOidcSecrets.new,
        open_id_discovery_service: OpenIDConnect::Discovery::Provider::Config
      },
      inputs: %i(account service_id)
    ) do

      def call
        validate_secrets
        validate_provider_is_responsive
      end

      private

      def validate_secrets
        oidc_secrets
      end

      def oidc_secrets
        @oidc_secrets ||= @fetch_oidc_secrets.(
          service_id: @service_id,
            conjur_account: @account,
            required_variable_names: required_variable_names
        )
      end

      def required_variable_names
        @required_variable_names ||= %w(provider-uri id-token-user-property)
      end

      def validate_provider_is_responsive
        @open_id_discovery_service.discover!(provider_uri)
      rescue HTTPClient::ConnectTimeoutError => e
        raise_error(Err::ProviderDiscoveryTimeout, e)
      rescue => e
        raise_error(Err::ProviderDiscoveryFailed, e)
      end

      def raise_error(error_class, original_error)
        raise error_class.new(provider_uri, original_error.inspect)
      end

      def provider_uri
        oidc_secrets["provider-uri"]
      end
    end
  end
end
