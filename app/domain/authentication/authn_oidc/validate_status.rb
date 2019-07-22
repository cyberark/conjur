module Authentication
  module AuthnOidc

    Err = Errors::Authentication::AuthnOidc
    # Possible Errors Raised:
    #   ProviderDiscoveryTimeout
    #   ProviderDiscoveryFailed

    ValidateStatus = CommandClass.new(
      dependencies: {
        fetch_oidc_secrets: AuthnOidc::Util::FetchOidcSecrets.new,
        discover_oidc_provider: Authentication::AuthnOidc::DiscoverOIDCProvider.new
      },
      inputs: %i(account service_id)
    ) do

      def call
        validate_secrets
        validate_provider_is_responsive
      end

      private

      def validate_secrets
        fetch_oidc_secrets
      end

      def fetch_oidc_secrets
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
        @discover_oidc_provider.(
          provider_uri: provider_uri
        )
      end

      def provider_uri
        @oidc_secrets["provider-uri"]
      end
    end
  end
end
