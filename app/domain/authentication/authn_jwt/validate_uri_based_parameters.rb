module Authentication
  module AuthnJwt

    ValidateUriBasedParameters ||= CommandClass.new(
      dependencies: {
        # ValidateWebserviceIsWhitelisted calls ValidateAccountExists
        # we call there ValidateAccountExists for better readability an safety
        validate_account_exists: ::Authentication::Security::ValidateAccountExists.new,
        validate_webservice_is_whitelisted: Security::ValidateWebserviceIsWhitelisted.new
      },
      inputs: %i[authenticator_input enabled_authenticators]
    ) do

      # authenticator_input attributes
      #  :account - from uri - has explicit validation
      #  :authenticator_name - from uri - has implicit validation with service_id
      #  :service_id - from uri - has implicit validation with authenticator_name
      #  :username - can be from uri
      #    - validation is specific for authenticator
      #    - in jwt case undefined until token signature validation
      #  :credentials - the web request body - validation is specific for authenticator
      #  :client_ip - from metadata or request - depends username
      #  :request - the web request object

      def call
        validate_account_exists
        validate_webservice_is_whitelisted
      end

      private

      def validate_account_exists
        @validate_account_exists.(
          account: @authenticator_input.account
        )
      end

      def validate_webservice_is_whitelisted
        @validate_webservice_is_whitelisted.(
          webservice: webservice,
            account: @authenticator_input.account,
            enabled_authenticators: @enabled_authenticators
        )
      end

      def webservice
        @webservice ||= ::Authentication::Webservice.new(
          account: @authenticator_input.account,
          authenticator_name: @authenticator_input.authenticator_name,
          service_id: @authenticator_input.service_id
        )
      end
    end
  end
end
