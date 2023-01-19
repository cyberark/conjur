module Authentication
  module AuthnAzure

    # This class represents the restrictions that are set on a Conjur host regarding
    # the Azure resources that it can authenticate with Conjur from.
    # It consists a list of AzureResource objects which represent the resource
    # restriction that need to be met in an authentication request.
    #
    # For example, if `resources` includes the AzureResource:
    #   - type: "subscription-id"
    #   - value: "some-subscription-id"
    #
    # then this Conjur host can authenticate with Conjur only with an Azure AD
    # token that was granted to an Azure resource that is part of the "some-subscription-id"
    # subscription
    class ResourceRestrictions

      attr_reader :resources

      AZURE_RESOURCE_TYPES = %w(subscription-id resource-group user-assigned-identity system-assigned-identity).freeze

      def initialize(role_annotations:, service_id:, logger:)
        @role_annotations = role_annotations
        @service_id       = service_id
        @logger           = logger

        init_resources
        validate_configuration
      end

      private

      def init_resources
        @constraints = ResourceRestrictionsConstraints.new
                           .add(restriction_name: "subscription-id", required: true)
                           .add(restriction_name: "resource-group", required: true)
                           .add(restriction_name: "user-assigned-identity", exclusive_group: "identity")
                           .add(restriction_name: "system-assigned-identity", exclusive_group: "identity")
      end

      # Verify that the Resource Restrictions were configured correctly.
      # Ideally this validation would have happened in the host creation but we
      # don't have that mechanism so we validate it here.
      def validate_configuration
        validate_constraints_are_permitted
        validate_required_constraints_exist
        validate_constraint_combinations
      end

      # validating that the annotations listed for the Conjur resource align with the permitted Azure constraints
      # For example, we do not allow the annotation 'authn-azure/blah'
      def validate_constraints_are_permitted
        (@role_annotations.keys-@constraints.permitted).each do |annotation_name|
          raise Errors::Authentication::ConstraintNotSupported.new(
              annotation_name,
              @constraints.permitted
          )
        end
      end

      def validate_required_constraints_exist
        (@constraints.required-@role_annotations.keys).each do |constraint|
          raise Errors::Authentication::RoleMissingConstraint, constraint
        end
        # validate_resource_constraint_exists "subscription-id"
        # validate_resource_constraint_exists "resource-group"
      end

      # validates that the resource restrictions do include logical resource constraint
      # combinations (e.g user_assigned_identity & system_assigned_identity)
      def validate_constraint_combinations
        # identifiers = %w(user-assigned-identity system-assigned-identity)

        @constraints.mutually_exclusive.each do |group_name, exclusive_group|
          exclusive_annotations = @role_annotations.keys & exclusive_group
          raise Errors::Authentication::IllegalConstraintCombinations, exclusive_annotations if exclusive_annotations.length > 1
        end
      end
    end
  end
end

class ResourceRestrictionsConstraints

  attr_reader :permitted, :required, :mutually_exclusive

  def initialize
    @permitted = []
    @required = []
    @mutually_exclusive = {}
  end

  def add(restriction_name:, required: false, exclusive_group: nil)
    @permitted << restriction_name
    @required << restriction_name if required
    (@mutually_exclusive[exclusive_group] ||= []) << restriction_name if exclusive_group.present?
    self
  end
end