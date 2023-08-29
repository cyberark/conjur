module Authentication
  module AuthnOidc

    ValidateStatus = CommandClass.new(
      dependencies: {
        discover_identity_provider: Authentication::OAuth::DiscoverIdentityProvider.new,
        required_variable_names: %w[provider-uri id-token-user-property],
        optional_variable_names: %w[ca-cert]
      },
      inputs: %i[account service_id]
    ) do
      def call
        validate_service_id_exists
        validate_secrets
        validate_provider_is_responsive
      end

      private

      def validate_service_id_exists
        raise Errors::Authentication::AuthnOidc::ServiceIdMissing unless @service_id
      end

      def validate_secrets
        oidc_authenticator_secrets
      end

      def oidc_authenticator_secrets
        @oidc_authenticator_secrets ||= Authentication::Util::FetchAuthenticatorSecrets.new(
          optional_variable_names: @optional_variable_names
        ).(
          service_id: @service_id,
          conjur_account: @account,
          authenticator_name: "authn-oidc",
          required_variable_names: @required_variable_names
        )
      end

      def validate_provider_is_responsive
        @discover_identity_provider.(
          provider_uri: provider_uri,
          ca_cert: ca_cert
        )
      end

      def provider_uri
        @oidc_authenticator_secrets["provider-uri"]
      end

      def ca_cert
        @oidc_authenticator_secrets["ca-cert"]
      end
    end
  end
end
