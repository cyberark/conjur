module Authentication
  module AuthnAzure

    Log = LogMessages::Authentication
    Err = Errors::Authentication::AuthnAzure
    # Possible Errors Raised: ConstraintNotSupported, MissingAnnotationConstraint, IllegalConstraintCombinations

    # This class defines an application identity of a given Conjur host.
    # The constructor initializes an ApplicationIdentity object and validates that
    # it is configured correctly.
    # The difference between the validation in this constructor and
    # the validation in ValidateApplicationIdentity is that here we validate that
    # the application identity is configured correctly, and thus is a valid application
    # identity. In ValidateApplicationIdentity we validate that the defined application
    # identity is actually the one we expect from Azure. This validation is done through
    # a combination of comparisons that are performed based on the type of assigned
    # identity provided.
    # For example, an application identity `some-namespace/blah/some-value` is not
    # valid and will fail the validation here. However, an application identity
    # `some-namespace/service-account/some-value` is a valid application identity
    # and will pass the validation here.
    # If the Azure-related annotations in the host defined in Conjur has Azure-specific
    # annotations that do not match the supplied JWT token, then it will fail the
    # validation of ValidateApplicationIdentity.
    class ApplicationIdentity

      def initialize(host_annotations:, service_id:)
        @host_annotations = host_annotations
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
        # check if annotations present are part of the permitted annotations for authn-azure
        validate_permitted_annotations

        # validate that a constraint exists on the required annotations
        validate_required_annotations_exist
        validate_constraint_combinations
      end

      def validate_permitted_annotations
        validate_prefixed_permitted_annotations("authn-azure/")
        validate_prefixed_permitted_annotations("authn-azure/#{@service_id}/")
      end

      # check if annotations with prefix is part of the permitted list
      def validate_prefixed_permitted_annotations prefix
        Rails.logger.debug(Log::ValidatingAnnotationsWithPrefix.new(prefix))

        prefixed_annotations(prefix).each do |annotation|
          annotation_name = annotation[:name]
          next if prefixed_permitted_constraints(prefix).include?(annotation_name)
          raise Err::ConstraintNotSupported.new(annotation_name.gsub(prefix, ""), permitted_constraints)
        end
      end

      def prefixed_annotations prefix
        @host_annotations.select do |a|
          annotation_name = a.values[:name]

          annotation_name.start_with?(prefix) &&
              # verify we take only annotations from the same level
              annotation_name.split('/').length == prefix.split('/').length + 1
        end
      end

      # add prefix to all permitted constraints
      def prefixed_permitted_constraints prefix
        permitted_constraints.map { |k| "#{prefix}#{k}" }
      end

      def validate_required_annotation_exists
        validate_annotations_exist "subscription-id"
        validate_annotations_exist "resource-group"
      end

      def validate_annotations_exist constraint
        raise Err::MissingAnnotationConstraint.new(constraint) unless constraint_from_annotation(constraint)
      end

      # validates that the required annotations (subscription_id and resource_group) exist in annotations
      def constraint_from_annotation constraint_name
        annotation_value("authn-azure/#{@service_id}/#{constraint_name}") ||
            annotation_value("authn-azure/#{constraint_name}")
      end

      def annotation_value name
        annotation = @host_annotations.find { |a| a.values[:name] == name }

        # return the value of the annotation if it exists, nil otherwise
        if annotation
          Rails.logger.debug(Log::RetrievedAnnotationValue.new(name))
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
        raise Err::IllegalConstraintCombinations, identifiers_constraints unless identifiers_constraints.length <= 1
      end

      def constraint_value constraint_name
        constraint_from_annotation(constraint_name)
      end
    end
  end
end
