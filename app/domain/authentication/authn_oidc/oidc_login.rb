require 'command_class'

module Authentication
  module AuthnOidc

    Login = CommandClass.new(
      dependencies: {
        common_class: ::Authentication::Common
      },
      inputs: %i(authenticator_input oidc_client_class env token_factory)
    ) do

      def call
        oidc_encrypted_token(@authenticator_input)
      end

      private

      def oidc_encrypted_token(input)
        request_body = AuthnOidc::OidcRequestBody.new(input.request)

        oidc_client = oidc_client(
          redirect_uri: request_body.redirect_uri,
          service_id: input.service_id,
          conjur_account: input.account
        )

        oidc_id_token_details = oidc_client.oidc_id_token_details!(request_body.authorization_code)
        validate_credentials(input, oidc_id_token_details)

        username = oidc_id_token_details.user_info.preferred_username
        input.username = username

        @common_class.validate_security(input, @env)
        @common_class.validate_origin(input)

        @common_class.audit_success(input)

        new_oidc_conjur_token(oidc_id_token_details)
      rescue => e
        @common_class.audit_failure(input, e)
        raise e
      end

      def oidc_client(redirect_uri:, service_id:, conjur_account:)
        oidc_client_configuration = AuthnOidc::GetOidcClientConfiguration.new.(
          redirect_uri: redirect_uri,
            service_id: service_id,
            conjur_account: conjur_account
        )

        @oidc_client_class.new(oidc_client_configuration)
      end

      def validate_credentials(input, oidc_id_token_details)
        AuthnOidc::Authenticator.new.(
          input: input,
            oidc_id_token_details: oidc_id_token_details
        )
      end

      def new_oidc_conjur_token(details)
        @token_factory.oidc_token(details)
      end
    end
  end
end
