require 'command_class'

module Authentication
  module AuthnAzure

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
        token_identity_from_claims
        validate_azure_annotations_are_permitted
        extract_application_identity_from_role
        validate_required_constraints_exist
        validate_constraint_combinations
        validate_token_identity_matches_annotations
      end

      private

      def parse_xms_mirid
        xms_mirid
      end

      def xms_mirid
        @xms_mirid ||= XmsMirid.new(@xms_mirid_token_field)
      end

      # xms_mirid is a term in Azure to define a claim that describes the resource that holds the encoding of the instance's
      # among other details the subscription_id, resource group, and provider identity needed for authorization.
      # xms_mirid is one of the fields in the JWT token. This function will extract the relevant information from
      # xms_mirid claim and populate a representative hash with the appropriate fields.
      def token_identity_from_claims
        @token_identity = {
          subscription_id: xms_mirid.subscriptions,
          resource_group:  xms_mirid.resource_groups
        }

        # determine which identity is provided in the token. If the token is
        # issued to a user-assigned identity then we take the identity name.
        # If the token is issued to a system-assigned identity then we take the
        # Object ID of the token.
        if xms_mirid.providers.include? "Microsoft.ManagedIdentity"
          @token_identity[:user_assigned_identity] = xms_mirid.providers.last
        else
          @token_identity[:system_assigned_identity] = @oid_token_field
        end
        @logger.debug(
          LogMessages::Authentication::AuthnAzure::ExtractedApplicationIdentityFromToken.new
        )
      end

      def validate_azure_annotations_are_permitted
        @validate_azure_annotations.call(
          role_annotations: role.annotations,
          service_id:       @service_id
        )
      end

      def extract_application_identity_from_role
        application_identity
      end

      def application_identity
        @application_identity ||= @application_identity_class.new(
          role_annotations: role.annotations,
          service_id:       @service_id,
          logger:           @logger
        )
      end

      def validate_required_constraints_exist
        validate_constraint_exists :subscription_id
        validate_constraint_exists :resource_group
      end

      def validate_constraint_exists constraint
        unless application_identity.constraints[constraint]
          raise Errors::Authentication::AuthnAzure::RoleMissingConstraint,
                annotation_type_constraint(constraint)
        end
      end

      # validates that the application identity doesn't include logical constraint
      # combinations (e.g user_assigned_identity & system_assigned_identity)
      def validate_constraint_combinations
        identifiers = %i(user_assigned_identity system_assigned_identity)

        identifiers_constraints = application_identity.constraints.keys & identifiers
        unless identifiers_constraints.length <= 1
          raise Errors::Authentication::IllegalConstraintCombinations,
                annotation_type_constraints(identifiers_constraints)
        end
      end

      def validate_token_identity_matches_annotations
        application_identity.constraints.each do |constraint|
          annotation_type  = constraint[0].to_s
          annotation_value = constraint[1]
          unless annotation_value == @token_identity[annotation_type.to_sym]
            raise Errors::Authentication::AuthnAzure::InvalidApplicationIdentity,
                  annotation_type_constraint(annotation_type)
          end
        end
        @logger.debug(LogMessages::Authentication::AuthnAzure::ValidatedApplicationIdentity.new)
      end

      def annotation_type_constraints constraints
        constraints.map { |constraint| annotation_type_constraint(constraint) }
      end

      # converts the constraint to be in annotation style (e.g resource-group
      # instead of resource_group) to enhance supportability
      def annotation_type_constraint constraint
        constraint.to_s.tr('_', '-')
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
