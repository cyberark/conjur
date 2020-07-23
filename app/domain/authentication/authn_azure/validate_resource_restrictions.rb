require 'command_class'

module Authentication
  module AuthnAzure

    ValidateResourceRestrictions = CommandClass.new(
      dependencies: {
        role_class:                  ::Role,
        resource_class:              ::Resource,
        resource_restrictions_class: ResourceRestrictions,
        logger:                      Rails.logger
      },
      inputs:       %i(account service_id username xms_mirid_token_field oid_token_field)
    ) do

      def call
        extract_resource_restrictions_from_role
        validate_resource_restrictions_match_request
      end

      private

      def extract_resource_restrictions_from_role
        resource_restrictions
      end

      def resource_restrictions
        @resource_restrictions ||= @resource_restrictions_class.new(
          role_annotations: role_annotations,
          service_id:       @service_id,
          logger:           @logger
        )
      end

      def validate_resource_restrictions_match_request
        resource_restrictions.resources.each do |resource_from_role|
          resource_from_request = resources_from_request.find { |resource_from_request| resource_from_request == resource_from_role }
          unless resource_from_request
            raise Errors::Authentication::AuthnAzure::InvalidResourceRestrictions, resource_from_role.type
          end
        end
        @logger.debug(LogMessages::Authentication::ValidatedResourceRestrictions.new)
      end

      # xms_mirid is a term in Azure to define a claim that describes the resource
      # that holds the encoding of the instance's among other details the subscription_id,
      # resource group, and provider identity needed for authorization.
      # xms_mirid is one of the fields in the JWT token. This function will extract the relevant information from
      # xms_mirid claim and populate a representative hash with the appropriate fields.
      def resources_from_request
        return @resources_from_request if @resources_from_request

        @resources_from_request = [
          AzureResource.new(
            type: "subscription-id",
            value: xms_mirid.subscriptions
          ),
          AzureResource.new(
            type: "resource-group",
            value: xms_mirid.resource_groups
          )
        ]

        # determine which identity is provided in the token. If the token is
        # issued to a user-assigned identity then we take the identity name.
        # If the token is issued to a system-assigned identity then we take the
        # Object ID of the token.
        if xms_mirid.providers.include? "Microsoft.ManagedIdentity"
          @resources_from_request.push(
            AzureResource.new(
              type: "user-assigned-identity",
              value: xms_mirid.providers.last
            )
          )
        else
          @resources_from_request.push(
            AzureResource.new(
              type: "system-assigned-identity",
              value: @oid_token_field
            )
          )
        end
        @logger.debug(LogMessages::Authentication::AuthnAzure::ExtractedResourceRestrictionsFromToken.new)
        @resources_from_request
      end

      def xms_mirid
        @xms_mirid ||= XmsMirid.new(@xms_mirid_token_field)
      end

      def role_annotations
        @role_annotations ||= role.annotations
      end

      def role
        return @role if @role

        @role = @resource_class[role_id]
        raise Errors::Authentication::Security::RoleNotFound, role_id unless @role
        @role
      end

      def role_id
        @role_id ||= @role_class.roleid_from_username(@account, @username)
      end
    end
  end
end
