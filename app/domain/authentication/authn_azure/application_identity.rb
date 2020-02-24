module Authentication
  module AuthnAzure

    Log = LogMessages::Authentication::AuthnAzure
    Err = Errors::Authentication::AuthnAzure
    # Possible Errors Raised: ConstraintNotSupported, MissingConstraint, IllegalConstraintCombinations

    # This class defines an Azure application identity of a given Conjur resource.
    # The constructor initializes an ApplicationIdentity object and validates that
    # it is configured correctly.
    # The difference between the validation in this constructor and
    # the validation in ValidateApplicationIdentity is that here we validate that
    # the application identity is configured correctly, and thus is a valid application
    # identity. In ValidateApplicationIdentity we validate that the defined application
    # identity is actually the one we expect from Azure. This validation is done through
    # a combination of comparisons that are performed based on the type of assigned
    # identity provided.
    # For example, an application identity `authn-azure/some-value` is not
    # valid and will fail the validation here. For example, application identity like
    # `authn-azure/subscription-id` or `authn-azure/<service-id>/subscription-id`
    # defined in the Conjur resource's annotations is a valid application identity
    # because `subscription_id` is one of the defined, accepted constraints and will pass
    # the validation here.
    # If the Azure-related annotations in the resource defined in Conjur has Azure-specific
    # annotations that do not match the supplied JWT token, then it will fail the
    # validation of ValidateApplicationIdentity.
    class ApplicationIdentity

      def initialize(role_annotations:, service_id:)
        @role_annotations = role_annotations
        @service_id       = service_id

        validate
      end

      def constraints
        @constraints ||= {
          subscription_id:          constraint_value("subscription-id"),
          resource_group:           constraint_value("resource-group"),
          user_assigned_identity:   constraint_value("user-assigned-identity"),
          system_assigned_identity: constraint_value("system-assigned-identity"),
        }.compact
      end

      private

      # validate that the application identity is defined correctly
      def validate
        validate_azure_annotations_are_permitted
        validate_required_constraints_exist
        validate_constraint_combinations
      end

      # validating that the annotations listed for the Conjur resource align with the permitted Azure constraints
      def validate_azure_annotations_are_permitted
        validate_prefixed_permitted_annotations("authn-azure/")
        validate_prefixed_permitted_annotations("authn-azure/#{@service_id}/")
      end

      # check if annotations with the given prefix is part of the permitted list
      def validate_prefixed_permitted_annotations prefix
        Rails.logger.debug(LogMessages::Authentication::ValidatingAnnotationsWithPrefix.new(prefix))

        prefixed_annotations(prefix).each do |annotation|
          annotation_name = annotation[:name]
          next if prefixed_permitted_constraints(prefix).include?(annotation_name)
          raise Err::ConstraintNotSupported.new(annotation_name.gsub(prefix, ""), permitted_constraints)
        end
      end

      def prefixed_annotations prefix
        @role_annotations.select do |a|
          annotation_name = a.values[:name]

          annotation_name.start_with?(prefix) &&
            # verify we take only annotations from the same level
            annotation_name.split('/').length == prefix.split('/').length + 1
        end
      end

      # add prefix to all permitted constraints
      def prefixed_permitted_constraints prefix
        permitted_constraints.map {|k| "#{prefix}#{k}"}
      end

      def validate_required_constraints_exist
        validate_constraint_exists :subscription_id
        validate_constraint_exists :resource_group
      end

      def validate_constraint_exists constraint
        raise Err::MissingConstraint.new(constraint) unless constraints[constraint]
      end

      # check the `service-id` specific constraint first to be more granular
      def constraint_from_annotation constraint_name
        annotation_value("authn-azure/#{@service_id}/#{constraint_name}") ||
          annotation_value("authn-azure/#{constraint_name}")
      end

      def annotation_value name
        annotation = @role_annotations.find {|a| a.values[:name] == name}

        # return the value of the annotation if it exists, nil otherwise
        if annotation
          Rails.logger.debug(LogMessages::Authentication::RetrievedAnnotationValue.new(name))
          annotation[:value]
        end
      end

      def permitted_constraints
        @permitted_constraints ||= %w(
          subscription-id resource-group user-assigned-identity system-assigned-identity
        )
      end

      # validates that the application identity doesn't include logical constraint
      # combinations (e.g user_assigned_identity & system_assigned_identity)
      def validate_constraint_combinations
        identifiers = %i(user_assigned_identity system_assigned_identity)

        identifiers_constraints = constraints.keys & identifiers
        raise Errors::Authentication::IllegalConstraintCombinations, identifiers_constraints unless identifiers_constraints.length <= 1
      end

      def constraint_value constraint_name
        constraint_from_annotation(constraint_name)
      end
    end
  end
end
