require 'command_class'

module Authentication
  module AuthnOidc

    Authenticate = CommandClass.new(
      dependencies: {
        common_class: ::Authentication::Common
      },
      inputs: %i(authenticator_input token_factory env)
    ) do

      def call
        conjur_token_oidc(@authenticator_input)
      end

      private

      def conjur_token_oidc(input)
        oidc_conjur_token = oidc_conjur_token(input)

        username = oidc_conjur_token.user_name
        input.username = username

        @common_class.validate_security(input, @env)
        @common_class.validate_origin(input)

        @common_class.audit_success(input)

        new_token(input)
      rescue => e
        @common_class.audit_failure(input, e)
        raise e
      end

      def oidc_conjur_token(input)
        AuthnOidc::GetOidcConjurToken.new.(
          request_body: input.request.body.read
        )
      end

      def new_token(input)
        @token_factory.signed_token(
          account: input.account,
          username: input.username
        )
      end
    end
  end
end
