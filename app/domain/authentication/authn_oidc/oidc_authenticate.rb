require 'command_class'

module Authentication
  module AuthnOidc

    Authenticate = CommandClass.new(
      dependencies: {
        enabled_authenticators: ENV['CONJUR_AUTHENTICATORS'],
        token_factory:          OidcTokenFactory.new,
        validate_security:      ::Authentication::ValidateSecurity.new,
        validate_origin:        ::Authentication::ValidateOrigin.new,
        audit_event:            ::Authentication::AuditEvent.new
      },
      inputs:       %i(authenticator_input)
    ) do

      def call
        conjur_token_oidc(@authenticator_input)
      end

      private

      def conjur_token_oidc(input)
        oidc_conjur_token = oidc_conjur_token(input)

        username = oidc_conjur_token.user_name
        input    = input.update(username: username)

        @validate_security.(input: input, enabled_authenticators: @enabled_authenticators)

        @validate_origin.(input: input)

        @audit_event.(input: input, success: true, message: nil)

        new_token(input)
      rescue => e
        unless input.username.nil?
          @audit_event.(input: input, success: false, message: e.message)
        end
        raise e
      end

      def oidc_conjur_token(input)
        AuthnOidc::GetOidcConjurToken.new.(
          request_body: input.request.body.read
        )
      end

      def new_token(input)
        @token_factory.signed_token(
          account:  input.account,
          username: input.username
        )
      end
    end
  end
end
