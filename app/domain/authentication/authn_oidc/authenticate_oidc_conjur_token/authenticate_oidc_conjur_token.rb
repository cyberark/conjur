require 'command_class'

module Authentication
  module AuthnOidc
    module AuthenticateOidcConjurToken

      Authenticate = CommandClass.new(
        dependencies: {
          validate_and_decrypt_oidc_conjur_token: ValidateAndDecryptOidcConjurToken.new,
          enabled_authenticators: ENV['CONJUR_AUTHENTICATORS'],
          token_factory: OidcTokenFactory.new,
          validate_security: ::Authentication::Security::ValidateSecurity.new,
          validate_origin: ::Authentication::ValidateOrigin.new,
          audit_event: ::Authentication::AuditEvent.new
        },
        inputs: %i(authenticator_input)
      ) do

        def call
          validate_and_decrypt_oidc_conjur_token
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

        def validate_and_decrypt_oidc_conjur_token
          oidc_conjur_token
        end

        def add_username_to_input
          username = oidc_conjur_token.user_name
          @authenticator_input = @authenticator_input.update(username: username)
        end

        def oidc_conjur_token
          @oidc_conjur_token ||= @validate_and_decrypt_oidc_conjur_token.(request_body: @authenticator_input.request.body.read)
        end

        def validate_security
          @validate_security.(
            webservice: @authenticator_input.webservice,
              account: @authenticator_input.account,
              user_id: @authenticator_input.username,
              enabled_authenticators: @enabled_authenticators
          )
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

        def new_token
          @token_factory.signed_token(
            account: @authenticator_input.account,
            username: @authenticator_input.username
          )
        end
      end
    end
  end
end
