# frozen_string_literal: true

require 'logs'

module Authentication

  module Security

    ValidateRoleCanAccessWebservice ||= CommandClass.new(
      dependencies: {
        role_class:                 ::Role,
        resource_class:             ::Resource,
        validate_webservice_exists: ::Authentication::Security::ValidateWebserviceExists.new,
        validate_account_exists:    ::Authentication::Security::ValidateAccountExists.new,
        logger:                     Rails.logger
      },
      inputs:       %i[webservice account user_id privilege]
    ) do

      def call
        validate_account_exists
        validate_role_is_defined

        # No further checks required for default conjur authn
        return if default_conjur_authn?

        validate_webservice_exists
        validate_role_has_access
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
        @validate_webservice_exists.(
          webservice: @webservice,
          account: @account
        )
      end

      def validate_role_is_defined
        raise Errors::Authentication::Security::RoleNotFound, @user_id unless user_role
      end

      def validate_role_has_access
        has_access = user_role.allowed_to?(@privilege, webservice_resource)
        unless has_access
          raise Errors::Authentication::Security::RoleNotAuthorizedOnResource.new(
            @user_id,
            @privilege,
            webservice_resource_id
          )
        end
      end

      def user_role_id
        @user_role_id ||= @role_class.roleid_from_username(@account, @user_id)
      end

      def user_role
        @user_role ||= @role_class[user_role_id]
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
