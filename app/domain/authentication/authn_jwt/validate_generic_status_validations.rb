module Authentication
  module AuthnJwt

    ValidateGenericStatusValidations ||= CommandClass.new(
      dependencies: {
        validate_webservice_is_whitelisted: ::Authentication::Security::ValidateWebserviceIsWhitelisted.new,
        validate_role_can_access_webservice: ::Authentication::Security::ValidateRoleCanAccessWebservice.new,
        validate_webservice_exists: ::Authentication::Security::ValidateWebserviceExists.new,
        enabled_authenticators: Authentication::InstalledAuthenticators.enabled_authenticators_str(ENV),
        audit_log: ::Audit.logger
      },
      inputs: %i[authenticator_status_input]
    ) do
      extend(Forwardable)
      def_delegators(:@authenticator_status_input, :authenticator_name, :account,
                     :username, :webservice, :status_webservice)

      def call
        validate_user_has_access_to_status_webservice
        validate_authenticator_webservice_exists
        validate_webservice_is_whitelisted
      end

      private

      def validate_user_has_access_to_status_webservice
        @validate_role_can_access_webservice.(
          webservice: status_webservice,
            account: account,
            user_id: username,
            privilege: 'read'
        )
      end

      def validate_webservice_is_whitelisted
        @validate_webservice_is_whitelisted.(
          webservice: webservice,
            account: account,
            enabled_authenticators: @enabled_authenticators
        )
      end

      def validate_authenticator_webservice_exists
        @validate_webservice_exists.(
          webservice: webservice,
            account: account
        )
      end
    end
  end
end
