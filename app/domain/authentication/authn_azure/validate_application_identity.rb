require 'command_class'

module Authentication
  module AuthnAzure

    Log = LogMessages::Authentication::AuthnAzure
    Err = Errors::Authentication::AuthnAzure

    # Possible Errors Raised: RoleNotFound, InvalidApplicationIdentity, XmsMiridParseError,
    # MissingRequiredFieldsInXmsMirid, MissingProviderFieldsInXmsMirid, MissingConstraint,
    # IllegalConstraintCombinations

    ValidateApplicationIdentity = CommandClass.new(
      dependencies: {
        role_class:                 ::Role,
        resource_class:             ::Resource,
        validate_azure_annotations: ValidateAzureAnnotations.new,
        application_identity_class: ApplicationIdentity,
        logger:                     Rails.logger
      },
      inputs:       %i(account service_id username xms_mirid_token_field oid_token_field)
    ) do

      def call
        parse_xms_mirid
        validate_xms_mirid_format
        token_identity_from_claims
        validate_azure_annotations_are_permitted
        extract_application_identity_from_role
        validate_required_constraints_exist
        validate_constraint_combinations
        validate_token_identity_matches_annotations
      end

      private

      def parse_xms_mirid
        xms_mirid_hash
      end

      def xms_mirid_hash
        @xms_mirid_hash ||= parsed_xms_mirid
      end

      # we expect the xms_mirid claim to be in the format of /subscriptions/<subscription-id>/...
      # therefore, we ignore the first slash of the xms_mirid claim and group the entries in key-value pairs
      # according to fields we need to retrieve from the claim.
      # ultimately, transforming "/key1/value1/key2/value2" to {"key1" => "value1", "key2" => "value2"}
      def parsed_xms_mirid
        begin
          split_xms_mirid = @xms_mirid_token_field.split('/')

          if split_xms_mirid.first == ''
            split_xms_mirid = split_xms_mirid.drop(1)
          end

          index = 0
          split_xms_mirid.each_with_object({}) do |property, xms_mirid_hash|
            case property
            when "subscriptions"
              xms_mirid_hash["subscriptions"] = split_xms_mirid[index + 1]
            when "resourcegroups"
              xms_mirid_hash["resourcegroups"] = split_xms_mirid[index + 1]
            when "providers"
              xms_mirid_hash["providers"] = split_xms_mirid[index + 1, 3]
            end
            index += 1
          end
        rescue => e
          raise Err::XmsMiridParseError.new(@xms_mirid_token_field, e.inspect)
        end
      end

      def validate_xms_mirid_format
        required_keys = %w(subscriptions resourcegroups providers)
        missing_keys  = required_keys - xms_mirid_hash.keys
        unless missing_keys.empty?
          raise Err::MissingRequiredFieldsInXmsMirid.new(missing_keys, @xms_mirid_token_field)
        end

        unless xms_mirid_hash["providers"].length == 3
          raise Err::MissingProviderFieldsInXmsMirid.new(@xms_mirid_token_field)
        end
      end

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
        if xms_mirid_hash["providers"].include? "Microsoft.ManagedIdentity"
          @token_identity[:user_assigned_identity] = xms_mirid_hash["providers"].last
        else
          @token_identity[:system_assigned_identity] = @oid_token_field
        end
        @logger.debug(Log::ExtractedApplicationIdentityFromToken.new)
      end

      def validate_azure_annotations_are_permitted
        @validate_azure_annotations.call(
          role_annotations: role.annotations,
          service_id: @service_id
        )
      end

      def extract_application_identity_from_role
        application_identity
      end

      def application_identity
        @application_identity ||= @application_identity_class.new(
          role_annotations: role.annotations,
          service_id:       @service_id
        )
      end

      def validate_required_constraints_exist
        validate_constraint_exists :subscription_id
        validate_constraint_exists :resource_group
      end

      def validate_constraint_exists constraint
        raise Err::RoleMissingConstraint.new(constraint) unless application_identity.constraints[constraint]
      end

      # validates that the application identity doesn't include logical constraint
      # combinations (e.g user_assigned_identity & system_assigned_identity)
      def validate_constraint_combinations
        identifiers = %i(user_assigned_identity system_assigned_identity)

        identifiers_constraints = application_identity.constraints.keys & identifiers
        raise Errors::Authentication::IllegalConstraintCombinations, identifiers_constraints unless identifiers_constraints.length <= 1
      end

      def validate_token_identity_matches_annotations
        application_identity.constraints.each do |constraint|
          annotation_type  = constraint[0].to_s
          annotation_value = constraint[1]
          unless annotation_value == @token_identity[annotation_type.to_sym]
            raise Err::InvalidApplicationIdentity.new(annotation_type)
          end
        end
        @logger.debug(Log::ValidatedApplicationIdentity.new)
      end

      def role
        @role ||= @resource_class[role_id].tap do |role|
          raise Errors::Authentication::Security::RoleNotFound, role_id unless role
        end
      end

      def role_id
        @role_id ||= @role_class.roleid_from_username(@account, @username)
      end
    end
  end
end
