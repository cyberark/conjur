require 'command_class'

# This class
module Authentication
  module AuthnJwt

    ValidateInput ||= CommandClass.new(
      dependencies: {
        # ValidateWebserviceIsWhitelisted is also calling ValidateAccountExists
        # it's better to be explicit and on the safe side
        validate_account_exists: ::Authentication::Security::ValidateAccountExists.new,
        validate_webservice_is_whitelisted: ::Authentication::Security::ValidateWebserviceIsWhitelisted.new,
        jwt_validate_body: Authentication::AuthnJwt::ValidateRequestBody.new
      },
      inputs: %i[authentication_parameters enabled_authenticators]
    ) do

      def call
        validate_account_exists
        validate_webservice_is_whitelisted
        jwt_validate_body
      end

      private

      def validate_account_exists
        @validate_account_exists.(
          account: @authentication_parameters.account
        )
      end

      def validate_webservice_is_whitelisted
        @validate_webservice_is_whitelisted.(
          webservice: webservice,
          account: @authentication_parameters.account,
          enabled_authenticators: @enabled_authenticators
        )
      end

      def jwt_validate_body
        @jwt_validate_body.(
          body_string: @authentication_parameters.request.body.read
        )
      end

      def webservice
        @webservice ||= ::Authentication::Webservice.new(
          account: @authentication_parameters.account,
          authenticator_name: @authentication_parameters.authenticator_name,
          service_id: @authentication_parameters.service_id
        )
      end

    end
  end
end
