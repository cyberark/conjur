module Authentication
  module AuthnOidc

    Err = Errors::Authentication::AuthnOidc
    # Possible Errors Raised:
    #   ProviderDiscoveryTimeout
    #   ProviderDiscoveryFailed

    ValidateStatus = CommandClass.new(
      dependencies: {
        fetch_authenticator_secrets: Authentication::Util::FetchAuthenticatorSecrets.new,
        discover_oidc_provider: Authentication::OAuth::DiscoverIdentityProvider.new
      },
      inputs: %i(account service_id)
    ) do

      def call
        validate_secrets
        validate_provider_is_responsive
      end

      private

      def validate_secrets
        oidc_authenticator_secrets
      end

      def oidc_authenticator_secrets
        @oidc_authenticator_secrets ||= @fetch_authenticator_secrets.(
          service_id: @service_id,
          conjur_account: @account,
          authenticator_name: "authn-oidc",
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
        @oidc_authenticator_secrets["provider-uri"]
      end
    end
  end
end
