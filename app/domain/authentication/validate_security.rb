# frozen_string_literal: true

require 'authentication/webservices'
require 'authentication/validate_webservice_access'
require 'authentication/validate_whitelisted_webservice'

module Authentication

  module Security

    # Possible Errors Raised:
    # AccountNotDefined, WebserviceNotFound, AuthenticatorNotWhitelisted,
    # RoleNotFound, RoleNotAuthorizedOnResource

    ValidateSecurity = CommandClass.new(
      dependencies: {
        validate_whitelisted_webservice: ::Authentication::Security::ValidateWhitelistedWebservice.new,
        validate_webservice_access: ::Authentication::Security::ValidateWebserviceAccess.new
      },
      inputs: %i(webservice account user_id enabled_authenticators)
    ) do

      def call
        # No checks required for default conjur authn
        return if default_conjur_authn?

        validate_webservice_is_whitelisted
        validate_user_has_access_to_webservice
      end

      private

      def default_conjur_authn?
        @webservice.authenticator_name ==
          ::Authentication::Common.default_authenticator_name
      end

      def validate_webservice_is_whitelisted
        @validate_whitelisted_webservice.(
          webservice: @webservice,
            account: @account,
            enabled_authenticators: @enabled_authenticators
        )
      end

      def validate_user_has_access_to_webservice
        @validate_webservice_access.(
          webservice: @webservice,
            account: @account,
            user_id: @user_id,
            privilege: 'authenticate'
        )
      end
    end
  end
end
