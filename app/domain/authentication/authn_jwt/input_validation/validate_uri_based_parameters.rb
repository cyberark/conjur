module Authentication
  module AuthnJwt
    module InputValidation
      ValidateUriBasedParameters ||= CommandClass.new(
        dependencies: {
          # ValidateWebserviceIsWhitelisted calls ValidateAccountExists
          # we call ValidateAccountExists for better readability and safety
          validate_account_exists: ::Authentication::Security::ValidateAccountExists.new,
          validate_webservice_is_whitelisted: Security::ValidateWebserviceIsWhitelisted.new
        },
        inputs: %i[authenticator_input enabled_authenticators]
      ) do

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
end
