# frozen_string_literal: true

module Authentication

  module Security

    ValidateWebserviceExists ||= CommandClass.new(
      dependencies: {
        role_class: ::Role,
        resource_class: ::Resource,
        validate_account_exists: ::Authentication::Security::ValidateAccountExists.new
      },
      inputs: %i[webservice account]
    ) do
      def call
        # No checks required for default conjur authn
        return if default_conjur_authn?

        validate_account_exists
        validate_webservice_exists
      end

      private

      def default_conjur_authn?
        @webservice.authenticator_name ==
          ::Authentication::Common.default_authenticator_name
      end

      def validate_account_exists
        @validate_account_exists.(
          account: @account
        )
      end

      def validate_webservice_exists
        raise Errors::Authentication::Security::WebserviceNotFound, @webservice.name, @account unless webservice_resource
      end

      def webservice_resource
        @resource_class[webservice_resource_id]
      end

      def webservice_resource_id
        @webservice.resource_id
      end
    end
  end
end
