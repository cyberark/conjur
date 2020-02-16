require 'command_class'

module Authentication
  module AuthnAzure

    Log = LogMessages::Authentication
    Err = Errors::Authentication::AuthnAzure
    # Possible Errors Raised: RoleNotFound, InvalidApplicationIdentity

    ValidateApplicationIdentity = CommandClass.new(
        dependencies: {
            role_class:                 Role,
            resource_class:             Resource,
            application_identity_class: ApplicationIdentity,
            logger:                     Rails.logger
        },
        inputs: %i(account, service_id, username, xms_mirid, oid)
    ) do

      def call
        parse_xms_mirid
        # compare xms_mirid with what is defined in annotations
        validate_application_identity
      end

      private

      # validate integrity of annotations
      def application_identity
        @application_identity ||= @application_identity_class.new(
            role_annotations: role.host_annotations,
            service_id: @service_id
        )
      end

      # convert host ID to full host ID, cucumber:host:somepolicy
      # TODO For a Conjur user, an incorrect full id will be returned
      def role_id
        @role_id ||= @role_class.roleid_from_username(@account, @username)
      end

      def role
        @role ||= @resource_class[role_id]
        raise SecurityErr::RoleNotFound(role_id) if @username.nil?
        @role
      end

      # xms_mirid is a term in Azure to define a claim that describes the resource that holds the encoding of the instance's
      # subscription, resource group, and provider identity needed for authorization. xms_mirid is one of the fields in
      # the JWT token. This function will extract the relevant information from xms_mirid claim and populate a representative
      # hash with the appropriate fields.
      def parse_xms_mirid
        field_split = @xms_mirid.split('/')
        xms_mirid_hash = Hash[field_split.each_slice(2).to_a]

        @token_identity = TokenIdentity.new(
            subscription_id: @xms_mirid_hash["subscriptions"],
            resource_group: @xms_mirid_hash["resourcegroups"]
        )

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
        if xms_mirid_hash["providers"] == "Microsoft.ManagedIdentity"
          logger.debug(Log::ExtractingIdentityForAuthentication.new(xms_mirid_hash["providers"] << "/" << xms_mirid_hash.keys[-1]))
          @token_identity.user_assigned_identity = xms_mirid_hash["userAssignedIdentities"]
        else
          logger.debug(Log::ExtractingIdentityForAuthentication.new(xms_mirid_hash["providers"] << "/" << xms_mirid_hash.keys[-1]))
          @token_identity.system_assigned_identity = @oid
        end
      end

      # validate the integrity of host annotations against the xms_mirid object representation
      def validate_application_identity
        logger.debug(Log::ValidatingApplicationIdentity.new(@xms_mirid_hash[@xms_mirid_hash.key[-1]]))
        application_identity.constraints.each do |constraint|
          annotation_type = constraint[0].to_s
          annotation_value = constraint[1]
          unless annotation_value == @token_identity[annotation_type]
            raise Err::InvalidApplicationIdentity.new(annotation_type)
          end
        end
        logger.debug(ValidatedApplicationIdentity.new(@xms_mirid_hash[@xms_mirid_hash.key[-1]]))
      end
    end
  end

end
