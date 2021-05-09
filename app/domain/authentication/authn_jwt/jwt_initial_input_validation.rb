require 'command_class'

# This class
module Authentication
  module AuthnJwt

    JWTInitialInputValidation ||= CommandClass.new(
      dependencies: {
        enabled_authenticators: InstalledAuthenticators.enabled_authenticators_str(ENV),
        # ValidateWebserviceIsWhitelisted calls ValidateAccountExists
        validate_webservice_is_whitelisted: Security::ValidateWebserviceIsWhitelisted.new,
      },
      inputs: %i[authentication_parameters]
    ) do

      def call
        validate_webservice_is_whitelisted
      end

      private

      def validate_webservice_is_whitelisted
        @validate_webservice_is_whitelisted.(
            webservice: webservice,
            account: @authentication_parameters.account,
            enabled_authenticators: @enabled_authenticators
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
