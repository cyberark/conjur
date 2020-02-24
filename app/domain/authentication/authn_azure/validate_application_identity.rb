require 'command_class'

module Authentication
  module AuthnAzure

    Log = LogMessages::Authentication::AuthnAzure
    Err = Errors::Authentication::AuthnAzure
    # Possible Errors Raised: RoleNotFound, InvalidApplicationIdentity

    ValidateApplicationIdentity = CommandClass.new(
      dependencies: {
        role_class:                 ::Role,
        resource_class:             ::Resource,
        application_identity_class: ApplicationIdentity,
        logger:                     Rails.logger
      },
      inputs:       %i(account service_id username xms_mirid_token_field oid_token_field)
    ) do

      def call
        validate_xms_mirid_format
        token_identity_from_claims
        compare_token_identity_with_annotations
      end

      private

      # xms_mirid is a term in Azure to define a claim that describes the resource that holds the encoding of the instance's
      # among other details the subscription_id, resource group, and provider identity needed for authorization.
      # xms_mirid is one of the fields in the JWT token. This function will extract the relevant information from
      # xms_mirid claim and populate a representative hash with the appropriate fields.
      def token_identity_from_claims
        @token_identity = {
          subscription_id: xms_mirid_hash["subscriptions"],
          resource_group:  xms_mirid_hash["resourcegroups"]
        }

        # determines which Azure assigned identity is provided in annotations
        # user-assigned-identity:
        #   - validates that the correct provider (Microsoft.ManagedIdentity) for a user identity is defined in the
        #     claim. If so, the 'user_assigned_identity' attribute will be added to the hash with the corresponding
        #     value from xms_mirid claim
        # system-assigned-identity:
        #   - validates that the correct provider (Microsoft.Compute) for a system identity is defined in the
        #     claim and its resource is one that we support. At current, we only support a virtualMachines resource.
        #     If these conditions are met, a 'system_assigned_identity' attribute will be added to the hash with its
        #     value being the oid field in the JWT token.
        @logger.debug(Log::ExtractingIdentityForAuthentication.new("#{xms_mirid_hash["providers"]}/#{xms_mirid_hash.keys[-1]}"))
        if xms_mirid_hash["providers"] == "Microsoft.ManagedIdentity"
          @token_identity[:user_assigned_identity] = xms_mirid_hash["userAssignedIdentities"]
        else
          @token_identity[:system_assigned_identity] = @oid_token_field
        end
      end

      def validate_xms_mirid_format
        valid_xms_mirid_format = xms_mirid_hash.length == 4 && xms_mirid_hash.key?("subscriptions" && "resourcegroups" && "providers")
        raise Err::ClaimInInvalidFormat unless valid_xms_mirid_format
      end

      # we expect the xms_mirid claim to be in the format of /subscriptions/<subscription-id>/...
      # therefore, we are ignoring the first slash of the xms_mirid field and grouping the entries in key-value pairs.
      # ultimately, transforming "/key1/value1/key2/value2" to {"key1" => "value1", "key2" => "value2"}
      def xms_mirid_hash
        @xms_mirid_hash ||= Hash[*@xms_mirid_token_field.split('/').drop(1)]
      end

      # validate the integrity of annotations against the xms_mirid object representation
      def compare_token_identity_with_annotations
        application_identity.constraints.each do |constraint|
          annotation_type  = constraint[0].to_s
          annotation_value = constraint[1]
          unless annotation_value == @token_identity[annotation_type.to_sym]
            raise Err::InvalidApplicationIdentity.new(annotation_type)
          end
        end
        @logger.debug(Log::ValidatedApplicationIdentity.new)
      end

      def application_identity
        @application_identity ||= @application_identity_class.new(
          role_annotations: role.annotations,
          service_id:       @service_id
        )
      end

      def role
        @role ||= @resource_class[role_id].tap do |role|
          raise SecurityErr::RoleNotFound(role_id) unless role
        end
      end

      def role_id
        @role_id ||= @role_class.roleid_from_username(@account, @username)
      end
    end
  end

end
