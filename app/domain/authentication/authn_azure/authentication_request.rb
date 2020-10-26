module Authentication
  module AuthnAzure

    class AuthenticationRequest
      def initialize(xms_mirid_token_field:, oid_token_field:)
        @xms_mirid_token_field = xms_mirid_token_field
        @oid_token_field = oid_token_field
      end

      def retrieve_attribute(attribute_name)
        case attribute_name
          when Restrictions::SUBSCRIPTION_ID then xms_mirid.subscriptions
          when Restrictions::RESOURCE_GROUP then xms_mirid.resource_groups
          when Restrictions::USER_ASSIGNED_IDENTITY
            xms_mirid.providers.last if user_assigned_identity?
          when Restrictions::SYSTEM_ASSIGNED_IDENTITY
            @oid_token_field unless user_assigned_identity?
        end
      end

      private

      # xms_mirid is a term in Azure to define a claim that describes the resource
      # that holds the encoding of the instance's among other details the subscription_id,
      # resource group, and provider identity needed for authorization.
      # xms_mirid is one of the fields in the JWT token.
      def xms_mirid
        @xms_mirid ||= XmsMirid.new(@xms_mirid_token_field)
      end

      # determine which identity is provided in the token. If the token is
      # issued to a user-assigned identity then we take the identity name.
      # If the token is issued to a system-assigned identity then we take the
      # Object ID of the token.
      def user_assigned_identity?
        xms_mirid.providers.include? "Microsoft.ManagedIdentity"
      end

    end
  end
end
