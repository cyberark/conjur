require 'command_class'

module Authentication
  module AuthnOidc
    module AuthenticateIdToken
      Authenticate = CommandClass.new(
        dependencies: {
          enabled_authenticators: ENV['CONJUR_AUTHENTICATORS'],
          fetch_oidc_secrets: AuthnOidc::Util::FetchOidcSecrets.new,
          token_factory: OidcTokenFactory.new,
          validate_security: ::Authentication::ValidateSecurity.new,
          validate_origin: ::Authentication::ValidateOrigin.new,
          audit_event: ::Authentication::AuditEvent.new,
          decode_and_verify_id_token: ::Authentication::AuthnOidc::AuthenticateIdToken::DecodeAndVerifyIdToken.new
        },
        inputs: %i(authenticator_input)
      ) do

        def call
          decode_and_verify_id_token
          add_username_to_input
          validate_security
          validate_origin
          audit_success
          new_token
        rescue => e
          audit_failure(e)
          raise e
        end

        private

        def decode_and_verify_id_token
          id_token_attributes
        end

        def add_username_to_input
          @authenticator_input = @authenticator_input.update(username: conjur_username)
        end

        def id_token_attributes
          @id_token_attributes ||= @decode_and_verify_id_token.(
            provider_uri: oidc_secrets["provider-uri"],
              id_token_jwt: request_body.id_token
          )
        end

        def request_body
          @request_body ||= AuthnOidc::AuthenticateIdToken::AuthenticateRequestBody.new(@authenticator_input.request)
        end

        def oidc_secrets
          @oidc_secrets ||= @fetch_oidc_secrets.(
            service_id: @authenticator_input.service_id,
              conjur_account: @authenticator_input.account,
              required_variable_names: required_variable_names
          )
        end

        def required_variable_names
          @required_variable_names ||= %w(provider-uri id-token-user-property)
        end

        def new_token
          @token_factory.signed_token(
            account: @authenticator_input.account,
            username: @authenticator_input.username
          )
        end

        def conjur_username
          id_token_username_field = oidc_secrets["id-token-user-property"]

          conjur_username = id_token_attributes[id_token_username_field]
          raise IdTokenFieldNotFoundOrEmpty, id_token_username_field unless conjur_username.present?

          conjur_username
        end

        def validate_security
          @validate_security.(input: @authenticator_input,
            enabled_authenticators: @enabled_authenticators)
        end

        def validate_origin
          @validate_origin.(input: @authenticator_input)
        end

        def audit_success
          @audit_event.(input: @authenticator_input, success: true, message: nil)
        end

        def audit_failure(err)
          @audit_event.(input: @authenticator_input, success: false, message: err.message)
        end
      end
    end
  end
end
