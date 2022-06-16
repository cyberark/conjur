module Authentication
  module AuthnOidc

    ValidateStatus = CommandClass.new(
      dependencies: {
        fetch_authenticator_secrets: Authentication::Util::FetchAuthenticatorSecrets.new,
        discover_identity_provider: Authentication::OAuth::DiscoverIdentityProvider.new,
        authenticator_repository: ::DB::Repository::AuthenticatorRepository.new
      },
      inputs: %i[account service_id]
    ) do
      def call
        validate_service_id_exists
        validate_secrets
        validate_provider_is_responsive
        validate_client_info
      end

      private

      def validate_service_id_exists
        raise Errors::Authentication::AuthnOidc::ServiceIdMissing unless @service_id
      end

      def validate_client_info
        oidc_login_url = ::Authentication::Handler::OidcAuthenticationHandler.new.generate_login_url(authenticator)
        RestClient.get(oidc_login_url)
      rescue RestClient::BadRequest
        raise Errors::Authentication::AuthnOidc::InvalidProviderConfig
      end

      def validate_secrets
        oidc_authenticator_secrets
        validate_secret_values if v2?
      end

      def validate_secret_values
        verify_secret("scope", scopes)
        verify_secret("claim-mapping", profile_claims)
        verify_secret("response-type", response_types)
      end

      def verify_secret(name, possible_values)
        oidc_authenticator_secrets[name].split.each do |value|
          raise Errors::Authentication::AuthnOidc::InvalidVariableValue.new(name, value) unless possible_values.include?(value)
        end
      end

      def authenticator_version
        @authenticator_version ||= authenticator.version
      end

      def authenticator
        @authenticator ||= @authenticator_repository.find(
          type: type,
          account: @account,
          service_id: @service_id
        )
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
        @required_variable_names ||= if v2?
          %w[provider-uri name response-type client-id client-secret claim-mapping state nonce redirect-uri scope]
        else
          %w[provider-uri id-token-user-property]
        end
      end

      def validate_provider_is_responsive
        @discover_identity_provider.(
          provider_uri: provider_uri
        )
      end

      def provider_uri
        @oidc_authenticator_secrets["provider-uri"]
      end

      def type
        'oidc'
      end

      def v2?
        authenticator_version == ::Authenticator::OidcAuthenticator::AUTH_VERSION_2
      end

      # Defined in OpenID Connect core specification section 5.1
      def profile_claims
        %w[name family_name given_name middle_name nickname preferred_username
        profile picture website gender birthdate zoneinfo locale updated_at]
      end

      def response_types
        %w[code id_token]
      end

      # Defined in OpenID Connect core specification section 5.4
      def scopes
        %w[openid profile email address phone]
      end
    end
  end
end
