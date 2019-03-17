require 'command_class'

module Authentication
  module AuthnOidc
    Authenticate = CommandClass.new(
      dependencies: {
        enabled_authenticators: ENV['CONJUR_AUTHENTICATORS'],
        fetch_oidc_secrets: AuthnOidc::FetchOidcSecrets.new,
        token_factory: OidcTokenFactory.new,
        validate_security: ::Authentication::ValidateSecurity.new,
        validate_origin: ::Authentication::ValidateOrigin.new,
        audit_event: ::Authentication::AuditEvent.new,
        decode_and_verify_id_token: ::Authentication::AuthnOidc::DecodeAndVerifyIdToken.new
      },
      inputs: %i(authenticator_input)
    ) do

      def call
        access_token(@authenticator_input)
      end

      private

      def access_token(input)
        request_body = AuthnOidc::AuthenticateRequestBody.new(input.request)

        required_variable_names = %w(provider-uri id-token-user-property)
        oidc_secrets = @fetch_oidc_secrets.(
          service_id: input.service_id,
            conjur_account: input.account,
            required_variable_names: required_variable_names
        )

        id_token_attributes = @decode_and_verify_id_token.(
          oidc_secrets["provider-uri"],
          request_body.id_token
        )

        input = input.update(
          username: conjur_username(
            id_token_attributes,
            oidc_secrets["id-token-user-property"]
          )
        )

        @validate_security.(input: input,
          enabled_authenticators: @enabled_authenticators)

        @validate_origin.(input: input)

        @audit_event.(input: input, success: true, message: nil)

        new_token(input)
      rescue => e
        @audit_event.(input: input, success: false, message: e.message)
        raise e
      end

      def new_token(input)
        @token_factory.signed_token(
          account: input.account,
          username: input.username
        )
      end

      def conjur_username(id_token_attributes, id_token_username_field)
        conjur_username = id_token_attributes[id_token_username_field]
        raise IdTokenFieldNotFound, id_token_username_field unless conjur_username.present?

        conjur_username
      end
    end
  end
end
