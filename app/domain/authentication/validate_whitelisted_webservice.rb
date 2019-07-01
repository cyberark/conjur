# frozen_string_literal: true

require 'authentication/webservices'

module Authentication

  module Security

    Err = Errors::Authentication::Security
    # Possible Errors Raised:
    # AccountNotDefined, NotWhitelisted

    ValidateWhitelistedWebservice = CommandClass.new(
      dependencies: {
        role_class: ::Role,
        webservices_class: ::Authentication::Webservices,
      },
      inputs: %i(webservice account enabled_authenticators)
    ) do

      def call
        # No checks required for default conjur authn
        return if default_conjur_authn?

        validate_account_exists
        validate_webservice_is_whitelisted
      end

      private

      def default_conjur_authn?
        @webservice.authenticator_name ==
          ::Authentication::Common.default_authenticator_name
      end

      def validate_account_exists
        raise Err::AccountNotDefined, @account unless account_admin_role
      end

      def account_admin_role
        @account_admin_role ||= @role_class["#{@account}:user:admin"]
      end

      def validate_webservice_is_whitelisted
        is_whitelisted = whitelisted_webservices.include?(@webservice)
        raise Err::NotWhitelisted, @webservice.name unless is_whitelisted
      end

      def whitelisted_webservices
        @webservices_class.from_string(
          @account,
          @enabled_authenticators || Authentication::Common.default_authenticator_name
        )
      end
    end
  end
end
