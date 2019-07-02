module Authentication
  module AuthnOidc

    ValidateStatus = CommandClass.new(
      dependencies: {
        fetch_oidc_secrets: AuthnOidc::Util::FetchOidcSecrets.new
      },
      inputs: %i(account service_id)
    ) do

      def call
        validate_secrets

        # validate OIDC provider is responsive
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
    end
  end
end
